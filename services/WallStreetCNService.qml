import QtQuick
import qs.Common
import qs.Services

pragma Singleton

Item {
    id: service

    // Public state
    readonly property var newsModel: _newsModel
    readonly property var favoritesModel: _favoritesModel
    readonly property bool isLoading: _requestInFlight
    readonly property string errorMessage: _errorMessage
    readonly property int totalFetched: _totalFetched
    readonly property string latestTitle: _latestTitle
    readonly property string latestSummary: _latestSummary
    readonly property int latestId: _latestId
    readonly property int newCount: _newCount

    // Configuration
    property string channel: "global-channel"
    property int pollInterval: 60000
    property int maxDays: 2
    property bool notificationsEnabled: true
    property bool importantOnly: false

    // LLM configuration
    property string llmHost: "localhost"
    property int llmPort: 11434
    property string llmModel: "qwen2.5:14b"

    onPollIntervalChanged: {
        _pollTimer.interval = pollInterval;
        if (_pollTimer.running) {
            _pollTimer.restart();
        }
    }

    onImportantOnlyChanged: _refilterModel()

    on_LatestTitleChanged: _summarizeLatest()

    // Internal
    property bool _requestInFlight: false
    property string _errorMessage: ""
    property int _totalFetched: 0
    property string _latestTitle: ""
    property string _latestSummary: ""
    property int _latestId: 0
    property int _newCount: 0
    property var _knownIds: ({})
    property var _favoritesIds: ({})

    signal newItemsArrived(var items)
    signal requestError(string message)

    property var _pluginService: null
    property string _pluginId: ""

    function init(pluginService, pluginId) {
        _pluginService = pluginService;
        _pluginId = pluginId;

        _loadFavorites();

        _pollTimer.interval = pollInterval;

        // Initial fetch
        fetchNews();

        // Start polling
        _pollTimer.start();
    }

    function fetchNews() {
        if (_requestInFlight) return;
        _requestInFlight = true;
        _errorMessage = "";

        var xhr = new XMLHttpRequest();
        var limit = 50;
        var url = "https://api-one-wscn.awtmt.com/apiv1/content/lives?channel=" + channel + "&limit=" + limit;

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;

            _requestInFlight = false;

            if (xhr.status !== 200) {
                _errorMessage = "HTTP " + xhr.status;
                requestError(_errorMessage);
                return;
            }

            try {
                var json = JSON.parse(xhr.responseText);
                if (json.code !== 20000) {
                    _errorMessage = json.message || "API error";
                    requestError(_errorMessage);
                    return;
                }
                _processItems(json.data.items || []);
            } catch (e) {
                _errorMessage = e.toString();
                requestError(_errorMessage);
            }
        };

        xhr.open("GET", url);
        xhr.timeout = 15000;
        xhr.send();
    }

    function _processItems(items) {
        var now = Math.floor(Date.now() / 1000);
        var cutoff = now - (maxDays * 86400);
        var newItems = [];
        var isFirstFetch = _totalFetched === 0;

        // Filter by date and importance
        var filtered = [];
        for (var i = 0; i < items.length; i++) {
            var item = items[i];
            if (item.display_time < cutoff) continue;
            if (importantOnly && (item.score || 0) < 2) continue;
            filtered.push(item);
        }

        // Find new items
        for (var j = 0; j < filtered.length; j++) {
            var f = filtered[j];
            if (!_knownIds[f.id]) {
                _knownIds[f.id] = true;
                newItems.push(f);
            }
        }

        // Update latest
        if (filtered.length > 0) {
            var latest = filtered[0];
            if (latest.id !== _latestId) {
                _latestId = latest.id;
                _latestTitle = latest.title || _stripHtml(latest.content_text || latest.content || "");
            }
        }

        // Rebuild model with deduplicated sorted items
        var allItems = [];

        // Add existing model items (apply importance filter)
        for (var k = 0; k < _newsModel.count; k++) {
            var existing = _newsModel.get(k);
            if (importantOnly && (existing.score || 0) < 2) continue;
            allItems.push({
                newsId: existing.newsId,
                title: existing.title,
                contentText: existing.contentText,
                displayTime: existing.displayTime,
                score: existing.score,
                uri: existing.uri,
                imageUrl: existing.imageUrl || "",
                isFavorite: existing.isFavorite
            });
        }

        // Merge new items (avoid duplicates)
        for (var m = 0; m < newItems.length; m++) {
            var ni = newItems[m];
            var dup = false;
            for (var n = 0; n < allItems.length; n++) {
                if (allItems[n].newsId === ni.id) { dup = true; break; }
            }
            if (!dup) {
                allItems.push(_itemToModel(ni));
            }
        }

        // Sort by displayTime descending
        allItems.sort(function(a, b) { return b.displayTime - a.displayTime; });

        // Filter by cutoff again
        var now2 = Math.floor(Date.now() / 1000);
        var cutoff2 = now2 - (maxDays * 86400);
        allItems = allItems.filter(function(it) { return it.displayTime >= cutoff2; });

        // Update model
        _newsModel.clear();
        for (var p = 0; p < allItems.length; p++) {
            _newsModel.append(allItems[p]);
        }

        _totalFetched += newItems.length;

        if (newItems.length > 0 && !isFirstFetch) {
            _newCount += newItems.length;
            newItemsArrived(newItems);
        }
    }

    function _itemToModel(item) {
        var title = item.title || "";
        var contentText = _stripHtml(item.content_text || item.content || "");
        var isFav = _favoritesIds[item.id] === true;

        return {
            newsId: item.id,
            title: title,
            contentText: contentText,
            displayTime: item.display_time,
            score: item.score || 0,
            uri: item.uri || "",
            imageUrl: _firstImageUrl(item),
            isFavorite: isFav
        };
    }

    function _firstImageUrl(item) {
        var lists = [item.cover_images, item.images];
        for (var i = 0; i < lists.length; i++) {
            var list = lists[i];
            if (!list || !Array.isArray(list)) continue;
            for (var j = 0; j < list.length; j++) {
                var image = list[j];
                if (!image) continue;
                if (typeof image === "string") return image;
                var url = image.url || image.uri || image.src || image.origin_url;
                if (url) return url;
            }
        }
        return "";
    }

    function _stripHtml(html) {
        if (!html) return "";
        return html.replace(/<[^>]*>/g, "").replace(/&nbsp;/g, " ").replace(/&amp;/g, "&")
            .replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, "\"").trim();
    }

    function _summarizeLatest() {
        if (_latestTitle.length <= 20) {
            _latestSummary = _latestTitle;
            return;
        }
        if (!llmHost || !llmModel) {
            _latestSummary = _latestTitle.substring(0, 20) + "...";
            return;
        }
        var xhr = new XMLHttpRequest();
        var url = "http://" + llmHost + ":" + llmPort + "/v1/chat/completions";
        var body = JSON.stringify({
            model: llmModel,
            messages: [{"role": "user", "content": "请用20个汉字以内总结以下新闻，只输出总结内容，不要有任何多余文字：\n" + _latestTitle}]
        });
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (xhr.status === 200) {
                try {
                    var json = JSON.parse(xhr.responseText);
                    _latestSummary = json.choices[0].message.content.trim();
                } catch(e) {
                    _latestSummary = _latestTitle.substring(0, 20) + "...";
                }
            } else {
                _latestSummary = _latestTitle.substring(0, 20) + "...";
            }
        };
        xhr.open("POST", url);
        xhr.timeout = 30000;
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.send(body);
    }

    function formatTime(timestamp) {
        var d = new Date(timestamp * 1000);
        var hh = d.getHours().toString().padStart(2, "0");
        var mm = d.getMinutes().toString().padStart(2, "0");
        return hh + ":" + mm;
    }

    function formatDate(timestamp) {
        var d = new Date(timestamp * 1000);
        var mm = (d.getMonth() + 1).toString().padStart(2, "0");
        var dd = d.getDate().toString().padStart(2, "0");
        return d.getFullYear() + "年" + mm + "月" + dd + "日";
    }

    function formatDateWeekday(timestamp) {
        var d = new Date(timestamp * 1000);
        var weekdays = ["星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六"];
        var mm = (d.getMonth() + 1).toString().padStart(2, "0");
        var dd = d.getDate().toString().padStart(2, "0");
        return d.getFullYear() + "年" + mm + "月" + dd + "日 " + weekdays[d.getDay()];
    }

    function isSameDay(ts1, ts2) {
        var d1 = new Date(ts1 * 1000);
        var d2 = new Date(ts2 * 1000);
        return d1.getFullYear() === d2.getFullYear() &&
               d1.getMonth() === d2.getMonth() &&
               d1.getDate() === d2.getDate();
    }

    function toggleFavorite(newsId) {
        var newFav = {};
        for (var i = 0; i < _newsModel.count; i++) {
            if (_newsModel.get(i).newsId == newsId) {
                var current = _newsModel.get(i).isFavorite;
                _newsModel.setProperty(i, "isFavorite", !current);
                if (!current) {
                    _favoritesIds[newsId] = true;
                } else {
                    delete _favoritesIds[newsId];
                }
                break;
            }
        }
        _rebuildFavoritesModel();
        _saveFavorites();
    }

    function isFavorite(newsId) {
        return _favoritesIds[newsId] === true;
    }

    function clearNewCount() {
        _newCount = 0;
    }

    function _rebuildFavoritesModel() {
        _favoritesModel.clear();
        for (var i = 0; i < _newsModel.count; i++) {
            var item = _newsModel.get(i);
            if (item.isFavorite) {
                _favoritesModel.append({
                    newsId: item.newsId,
                    title: item.title,
                    contentText: item.contentText,
                    displayTime: item.displayTime,
                    score: item.score,
                    uri: item.uri,
                    imageUrl: item.imageUrl || "",
                    isFavorite: true
                });
            }
        }
    }

    function _refilterModel() {
        var allItems = [];
        for (var i = 0; i < _newsModel.count; i++) {
            var existing = _newsModel.get(i);
            if (importantOnly && (existing.score || 0) < 2) continue;
            allItems.push({
                newsId: existing.newsId,
                title: existing.title,
                contentText: existing.contentText,
                displayTime: existing.displayTime,
                score: existing.score,
                uri: existing.uri,
                imageUrl: existing.imageUrl || "",
                isFavorite: existing.isFavorite
            });
        }
        _newsModel.clear();
        for (var j = 0; j < allItems.length; j++) {
            _newsModel.append(allItems[j]);
        }
    }

    function _saveFavorites() {
        if (!_pluginService) return;
        var ids = Object.keys(_favoritesIds);
        _pluginService.savePluginData(_pluginId, "favorites", ids);
    }

    function _loadFavorites() {
        if (!_pluginService) return;
        var ids = _pluginService.loadPluginData(_pluginId, "favorites");
        if (ids && Array.isArray(ids)) {
            for (var i = 0; i < ids.length; i++) {
                _favoritesIds[ids[i]] = true;
            }
        }
    }

    // Models
    ListModel {
        id: _newsModel
    }

    ListModel {
        id: _favoritesModel
    }

    // Poll timer
    Timer {
        id: _pollTimer
        interval: service.pollInterval
        repeat: true
        onTriggered: service.fetchNews()
    }
}

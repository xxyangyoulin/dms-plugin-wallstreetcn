import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "./components"
import "./services"

PluginComponent {
    id: root

    property bool showImportantOnly: pluginData.importantOnly !== undefined ? pluginData.importantOnly : false
    property int pollInterval: pluginData.pollInterval !== undefined ? pluginData.pollInterval : 60000

    readonly property string latestTitle: WallStreetCNService.latestTitle
    readonly property string latestSummary: WallStreetCNService.latestSummary
    readonly property int newCount: WallStreetCNService.newCount
    readonly property bool isLoading: WallStreetCNService.isLoading

    function loadValue(key, fallback) {
        var val = pluginData[key];
        return val !== undefined ? val : fallback;
    }

    function saveValue(key, value) {
        if (pluginService) {
            pluginService.savePluginData("wallstreetcn", key, value);
        }
    }

    Component.onCompleted: {
        WallStreetCNService.importantOnly = showImportantOnly;
        WallStreetCNService.pollInterval = pollInterval;
        WallStreetCNService.llmHost = loadValue("llmHost", "localhost");
        WallStreetCNService.llmPort = loadValue("llmPort", 11434);
        WallStreetCNService.llmModel = loadValue("llmModel", "qwen2.5:14b");
        WallStreetCNService.init(pluginService, "wallstreetcn");
    }

    onPluginDataChanged: {
        var newImportant = pluginData.importantOnly === true;
        if (newImportant !== WallStreetCNService.importantOnly) {
            WallStreetCNService.importantOnly = newImportant;
        }
        if (pluginData.pollInterval !== undefined) {
            WallStreetCNService.pollInterval = pluginData.pollInterval;
        }
        if (pluginData.llmHost !== undefined) {
            WallStreetCNService.llmHost = pluginData.llmHost;
        }
        if (pluginData.llmPort !== undefined) {
            WallStreetCNService.llmPort = pluginData.llmPort;
        }
        if (pluginData.llmModel !== undefined) {
            WallStreetCNService.llmModel = pluginData.llmModel;
        }
    }

    Connections {
        target: WallStreetCNService
        function onNewItemsArrived(items) {
            if (WallStreetCNService.notificationsEnabled && items.length > 0) {
                var msg = items.length === 1
                    ? (items[0].title || items[0].content_text || "新要闻")
                    : items.length + " 条新要闻";
                if (msg.length > 80) msg = msg.substring(0, 80) + "...";
                ToastService.showInfo(msg);
            }
        }
    }

    function refresh() {
        WallStreetCNService.fetchNews();
    }

    function toggleFavorite(newsId) {
        WallStreetCNService.toggleFavorite(newsId);
    }

    // Status bar pills
    horizontalBarPill: NewsStatusBar {
        orientation: Qt.Horizontal
        barThickness: root.barThickness
        latestTitle: root.latestTitle
        latestSummary: root.latestSummary
        newCount: root.newCount
        isLoading: root.isLoading
    }

    verticalBarPill: NewsStatusBar {
        orientation: Qt.Vertical
        barThickness: root.barThickness
        latestTitle: root.latestTitle
        latestSummary: root.latestSummary
        newCount: root.newCount
        isLoading: root.isLoading
    }

    popoutContent: Component {
        FocusScope {
            implicitWidth: 420
            implicitHeight: 600
            focus: true

            property var parentPopout: null

            Component.onCompleted: {
                Qt.callLater(function() {
                    forceActiveFocus();
                    WallStreetCNService.clearNewCount();
                });
            }

            Connections {
                target: parentPopout
                function onShouldBeVisibleChanged() {
                    if (parentPopout && !parentPopout.shouldBeVisible) {
                        // reset state when popup closes
                    }
                }
            }

            Column {
                anchors.fill: parent
                anchors.margins: Theme.spacingM
                spacing: Theme.spacingS

                // Header
                Row {
                    id: headerRow
                    width: parent.width
                    spacing: Theme.spacingS

                    DankIcon {
                        id: newsIcon
                        name: "newspaper"
                        size: Theme.iconSize
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        id: titleText
                        text: "华尔街见闻 · 要闻"
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Bold
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Item {
                        width: Math.max(0, headerRow.width - newsIcon.width - titleText.implicitWidth
                            - (loadingIcon.visible ? loadingIcon.width : 0) - importantToggleRow.implicitWidth
                            - refreshIcon.width - headerRow.spacing * 5)
                        height: 1
                    }

                    DankIcon {
                        id: loadingIcon
                        visible: root.isLoading
                        name: "sync"
                        size: Theme.iconSizeSmall
                        color: Theme.surfaceVariantText
                        anchors.verticalCenter: parent.verticalCenter

                        NumberAnimation on rotation {
                            from: 0; to: 360
                            duration: 1000
                            loops: Animation.Infinite
                            running: root.isLoading
                        }
                    }

                    Row {
                        id: importantToggleRow
                        spacing: Theme.spacingXS
                        anchors.verticalCenter: parent.verticalCenter

                        StyledText {
                            text: "重要"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        DankToggle {
                            checked: WallStreetCNService.importantOnly
                            anchors.verticalCenter: parent.verticalCenter
                            onToggled: isChecked => {
                                WallStreetCNService.importantOnly = isChecked;
                                root.saveValue("importantOnly", isChecked);
                            }
                        }
                    }

                    DankIcon {
                        id: refreshIcon
                        name: "refresh"
                        size: Theme.iconSizeSmall
                        color: Theme.surfaceVariantText
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: mouseArea.containsMouse ? 1 : 0.6

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: root.refresh()
                        }
                    }
                }

                // Error message
                Row {
                    id: errorRow
                    visible: WallStreetCNService.errorMessage.length > 0
                    width: parent.width
                    spacing: Theme.spacingXS

                    DankIcon {
                        name: "error"
                        size: Theme.iconSizeSmall
                        color: Theme.error
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: WallStreetCNService.errorMessage
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.error
                        width: parent.width - Theme.iconSizeSmall - Theme.spacingXS
                        wrapMode: Text.WordWrap
                    }
                }

                // News list
                ListView {
                    id: newsList
                    width: parent.width
                    height: parent.height - headerRow.height - errorRow.height
                        - favSection.height
                        - Theme.spacingS * (1 + (errorRow.visible ? 1 : 0) + (favSection.visible ? 1 : 0))
                    clip: true
                    spacing: Theme.spacingXS
                    model: WallStreetCNService.newsModel

                    delegate: Column {
                        width: newsList.width

                        // Date separator
                        StyledText {
                            readonly property var prevItem: WallStreetCNService.newsModel.count > model.index && model.index > 0
                                ? WallStreetCNService.newsModel.get(model.index - 1) : null
                            visible: model.index === 0 || !prevItem
                                || !WallStreetCNService.isSameDay(model.displayTime, prevItem.displayTime)
                            text: visible ? WallStreetCNService.formatDateWeekday(model.displayTime) : ""
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.DemiBold
                            color: Theme.surfaceVariantText
                            topPadding: Theme.spacingS
                            bottomPadding: Theme.spacingXS
                        }

                        NewsItem {
                            width: parent.width
                            newsId: model.newsId
                            title: model.title
                            contentText: model.contentText
                            displayTime: model.displayTime
                            score: model.score
                            uri: model.uri
                            imageUrl: model.imageUrl || ""
                            isFavorite: model.isFavorite
                            onToggleFavorite: function(id) { root.toggleFavorite(id); }
                        }
                    }
                }

                // Favorites section
                Column {
                    id: favSection
                    width: parent.width
                    visible: WallStreetCNService.favoritesModel.count > 0
                    height: visible ? implicitHeight : 0
                    spacing: Theme.spacingXS

                    StyledRect {
                        width: parent.width
                        height: 1
                        color: Theme.surfaceVariant
                    }

                    Row {
                        spacing: Theme.spacingS

                        DankIcon {
                            name: "favorite"
                            size: Theme.iconSizeSmall
                            color: Theme.error
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: "收藏 (" + WallStreetCNService.favoritesModel.count + ")"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.DemiBold
                            color: Theme.surfaceText
                        }
                    }

                    ListView {
                        id: favListView
                        width: parent.width
                        height: Math.min(contentHeight, 200)
                        clip: true
                        spacing: Theme.spacingXS
                        model: WallStreetCNService.favoritesModel

                        delegate: NewsItem {
                            width: favListView.width
                            newsId: model.newsId
                            title: model.title
                            contentText: model.contentText
                            displayTime: model.displayTime
                            score: model.score
                            uri: model.uri
                            imageUrl: model.imageUrl || ""
                            isFavorite: true
                            onToggleFavorite: function(id) { root.toggleFavorite(id); }
                        }
                    }
                }
            }
        }
    }
}

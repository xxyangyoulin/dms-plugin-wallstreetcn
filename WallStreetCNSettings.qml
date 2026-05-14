import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import "./services"

PluginSettings {
    id: root

    pluginId: "wallstreetcn"

    property string intervalValue: ""
    property bool intervalLoaded: false

    function loadIntervalValue() {
        if (!pluginService)
            return;
        var ms = loadValue("pollInterval", 60000);
        intervalValue = (ms / 1000).toString();
        intervalLoaded = true;
    }

    function persistIntervalValue() {
        if (!intervalLoaded)
            return;
        var val = parseInt(intervalValue);
        if (!isNaN(val) && val >= 10 && val <= 600) {
            saveValue("pollInterval", val * 1000);
        }
    }

    Component.onCompleted: Qt.callLater(loadIntervalValue)
    onPluginServiceChanged: Qt.callLater(loadIntervalValue)

    StyledText {
        text: "华尔街见闻"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        text: "实时追踪华尔街见闻要闻快讯，新内容自动推送至状态栏，支持收藏重要资讯。"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        width: parent.width
        wrapMode: Text.WordWrap
    }

    StyledRect {
        width: parent.width
        height: 1
        color: Theme.surfaceVariant
    }

    StyledText {
        text: "轮询"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.DemiBold
        color: Theme.surfaceText
    }

    Column {
        width: parent.width
        spacing: Theme.spacingS

        StyledText {
            text: "刷新间隔（秒）"
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Medium
            color: Theme.surfaceText
        }

        StyledText {
            text: "建议设置在 30-300 秒之间，过短的间隔会增加网络请求频率。"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            width: parent.width
            wrapMode: Text.WordWrap
        }

        DankTextField {
            id: intervalField
            width: parent.width
            placeholderText: "60"
            text: root.intervalValue

            onTextEdited: root.intervalValue = text
            onEditingFinished: root.persistIntervalValue()
            onActiveFocusChanged: {
                if (!activeFocus) {
                    root.intervalValue = text;
                    root.persistIntervalValue();
                }
            }
        }
    }

    StyledRect {
        width: parent.width
        height: 1
        color: Theme.surfaceVariant
    }

    StyledText {
        text: "关于"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.DemiBold
        color: Theme.surfaceText
    }

    StyledText {
        text: "数据来源：华尔街见闻 wallstreetcn.com\n本插件仅用于个人学习，请遵守相关服务条款。"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        width: parent.width
        wrapMode: Text.WordWrap
    }
}

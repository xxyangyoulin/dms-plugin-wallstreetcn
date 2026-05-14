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

    property string llmHostValue: ""
    property string llmPortValue: ""
    property string llmModelValue: ""
    property bool llmLoaded: false

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

    function loadLlmValues() {
        if (!pluginService)
            return;
        llmHostValue = loadValue("llmHost", "localhost");
        llmPortValue = loadValue("llmPort", 11434).toString();
        llmModelValue = loadValue("llmModel", "qwen2.5:14b");
        llmLoaded = true;
    }

    function persistLlmValues() {
        if (!llmLoaded)
            return;
        saveValue("llmHost", llmHostValue);
        var port = parseInt(llmPortValue);
        if (!isNaN(port) && port > 0 && port <= 65535) {
            saveValue("llmPort", port);
        }
        if (llmModelValue.length > 0) {
            saveValue("llmModel", llmModelValue);
        }
    }

    Component.onCompleted: {
        Qt.callLater(loadIntervalValue);
        Qt.callLater(loadLlmValues);
    }
    onPluginServiceChanged: {
        Qt.callLater(loadIntervalValue);
        Qt.callLater(loadLlmValues);
    }

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
        text: "AI 摘要"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.DemiBold
        color: Theme.surfaceText
    }

    Column {
        width: parent.width
        spacing: Theme.spacingS

        StyledText {
            text: "状态栏标题超过20字时，使用本地 LLM 自动总结。"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            width: parent.width
            wrapMode: Text.WordWrap
        }

        Row {
            width: parent.width
            spacing: Theme.spacingS

            DankTextField {
                id: hostField
                width: parent.width * 0.55
                placeholderText: "localhost"
                text: root.llmHostValue
                onTextEdited: root.llmHostValue = text
                onEditingFinished: root.persistLlmValues()
                onActiveFocusChanged: {
                    if (!activeFocus) {
                        root.llmHostValue = text;
                        root.persistLlmValues();
                    }
                }
            }

            DankTextField {
                id: portField
                width: parent.width * 0.4
                placeholderText: "11434"
                text: root.llmPortValue
                onTextEdited: root.llmPortValue = text
                onEditingFinished: root.persistLlmValues()
                onActiveFocusChanged: {
                    if (!activeFocus) {
                        root.llmPortValue = text;
                        root.persistLlmValues();
                    }
                }
            }
        }

        DankTextField {
            id: modelField
            width: parent.width
            placeholderText: "qwen2.5:14b"
            text: root.llmModelValue
            onTextEdited: root.llmModelValue = text
            onEditingFinished: root.persistLlmValues()
            onActiveFocusChanged: {
                if (!activeFocus) {
                    root.llmModelValue = text;
                    root.persistLlmValues();
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

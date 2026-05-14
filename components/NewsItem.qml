import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import "../services"

Item {
    id: root

    property string newsId: ""
    property string title: ""
    property string contentText: ""
    property int displayTime: 0
    property int score: 0
    property string uri: ""
    property string imageUrl: ""
    property bool isFavorite: false
    property bool expanded: false
    property bool showDate: false
    property string dateText: ""

    signal toggleFavorite(var newsId)

    implicitWidth: 400
    implicitHeight: column.height + Theme.spacingS * 2

    StyledRect {
        anchors.fill: parent
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh
        border.width: root.score >= 2 ? 1 : 0
        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
    }

    Column {
        id: column
        x: Theme.spacingM
        y: Theme.spacingS
        width: parent.width - Theme.spacingM * 2
        spacing: Theme.spacingXS

        Row {
            spacing: Theme.spacingS

            StyledText {
                text: WallStreetCNService.formatTime(root.displayTime)
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }

            Rectangle {
                visible: root.score >= 2
                width: importantLabel.implicitWidth + 8
                height: importantLabel.implicitHeight + 4
                radius: 4
                color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.1)
                anchors.verticalCenter: parent.verticalCenter

                StyledText {
                    id: importantLabel
                    anchors.centerIn: parent
                    text: "重要"
                    font.pixelSize: Theme.fontSizeSmall - 2
                    color: Theme.error
                    font.weight: Font.Medium
                }
            }
        }

        StyledText {
            visible: root.title.length > 0
            text: root.title
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.DemiBold
            color: Theme.surfaceText
            width: parent.width - favBtn.width - openBtn.width - Theme.spacingS * 2
            wrapMode: Text.WordWrap
        }

        Item {
            id: imageFrame
            visible: root.imageUrl.length > 0 && newsImage.status === Image.Ready
            width: parent.width
            height: visible ? 120 : 0
            clip: true

            StyledRect {
                anchors.fill: parent
                radius: Theme.cornerRadius
                color: Theme.surfaceContainer
            }

            Image {
                id: newsImage
                anchors.fill: parent
                source: root.imageUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
            }
        }

        StyledText {
            id: contentLabel
            text: root.contentText
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.surfaceText
            width: parent.width
            wrapMode: Text.WordWrap
            maximumLineCount: root.expanded ? 1000 : 4
            elide: root.expanded ? Text.ElideNone : Text.ElideRight
            lineHeightMode: Text.FixedHeight
            lineHeight: font.pixelSize * 1.5

            MouseArea {
                anchors.fill: parent
                enabled: contentLabel.truncated || root.expanded
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.expanded = !root.expanded
            }
        }
    }

    Item {
        id: openBtn
        visible: root.uri.length > 0
        width: Theme.iconSizeSmall + 16
        height: width
        anchors.right: favBtn.left
        anchors.rightMargin: Theme.spacingXS
        anchors.top: parent.top
        anchors.topMargin: Theme.spacingXS

        DankIcon {
            name: "open_in_new"
            size: Theme.iconSizeSmall
            color: openMouseArea.containsMouse ? Theme.primary : Theme.surfaceVariantText
            anchors.centerIn: parent
        }

        MouseArea {
            id: openMouseArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: Qt.openUrlExternally(root.uri)
        }
    }

    Item {
        id: favBtn
        width: Theme.iconSizeSmall + 16
        height: width
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacingXS
        anchors.top: parent.top
        anchors.topMargin: Theme.spacingXS

        DankIcon {
            name: root.isFavorite ? "favorite" : "favorite_border"
            size: Theme.iconSizeSmall
            color: root.isFavorite ? Theme.error : Theme.surfaceVariantText
            anchors.centerIn: parent
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleFavorite(root.newsId)
        }
    }
}

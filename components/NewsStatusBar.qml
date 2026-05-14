import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import "../services"

Item {
    id: root

    property int orientation: Qt.Horizontal
    property real barThickness: 0
    property string latestTitle: ""
    property int newCount: 0
    property bool isLoading: false

    implicitWidth: orientation === Qt.Vertical ? barThickness : statusBarRow.implicitWidth
    implicitHeight: orientation === Qt.Vertical ? statusBarCol.implicitHeight : barThickness

    Row {
        id: statusBarRow
        visible: root.orientation === Qt.Horizontal
        anchors.centerIn: parent
        spacing: Theme.spacingS

        DankIcon {
            name: "newspaper"
            size: Theme.barIconSize(root.barThickness, -4)
            color: Theme.widgetTextColor || Theme.surfaceText
            anchors.verticalCenter: parent.verticalCenter
        }

        StyledText {
            text: root.latestTitle.length > 30
                ? root.latestTitle.substring(0, 30) + "..."
                : root.latestTitle
            font.pixelSize: Theme.barTextSize(root.barThickness)
            color: Theme.widgetTextColor || Theme.surfaceText
            anchors.verticalCenter: parent.verticalCenter
            visible: root.latestTitle.length > 0
        }
    }

    Column {
        id: statusBarCol
        visible: root.orientation === Qt.Vertical
        anchors.centerIn: parent
        spacing: 2

        DankIcon {
            name: "newspaper"
            size: Theme.barIconSize(root.barThickness)
            color: Theme.widgetTextColor || Theme.surfaceText
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}

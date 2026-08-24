import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: limit

    property string label: ""
    property real remainingPercent: 0
    property string resetText: ""
    property color accentColor: "#8b5cf6"

    spacing: 3

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            Layout.fillWidth: true
            color: "#bfc7ce"
            font.pixelSize: 11
            text: limit.label
        }

        Text {
            color: "#f2f3f4"
            font.pixelSize: 11
            font.weight: Font.Medium
            text: Math.round(limit.remainingPercent) + "%"
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 4
        radius: 2
        color: "#34393e"

        Rectangle {
            width: parent.width * Math.max(0, Math.min(100, limit.remainingPercent)) / 100
            height: parent.height
            radius: parent.radius
            color: limit.accentColor
        }
    }

    Text {
        Layout.fillWidth: true
        color: "#7f8991"
        elide: Text.ElideRight
        font.pixelSize: 9
        horizontalAlignment: Text.AlignRight
        text: limit.resetText
    }
}

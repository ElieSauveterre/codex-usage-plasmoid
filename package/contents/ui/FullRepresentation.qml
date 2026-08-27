import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents

Item {
    id: full

    readonly property color accentColor: "#8b5cf6"

    required property real remainingPercent
    required property string planLabel
    required property string weeklyResetText
    required property bool loading
    required property string errorMessage
    required property string lastUpdatedText
    required property int resetCreditsAvailable
    required property string resetCreditExpiryText
    signal refreshRequested()

    Layout.minimumWidth: 250
    Layout.minimumHeight: implicitHeight
    Layout.preferredWidth: 260
    Layout.preferredHeight: implicitHeight
    implicitWidth: 260
    implicitHeight: full.resetCreditExpiryText.length > 0 ? 306 : 282

    Rectangle {
        anchors.fill: parent
        color: "#202428"
        radius: 6

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 6

            Item {
                Layout.fillWidth: true
                implicitHeight: 28

                Text {
                    anchors.centerIn: parent
                    color: "#f2f3f4"
                    font.pixelSize: 16
                    font.weight: Font.Medium
                    text: qsTr("Codex Usage")
                }

                Rectangle {
                    visible: full.planLabel.length > 0
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#2d3338"
                    radius: 7
                    width: planText.implicitWidth + 10
                    height: 20

                    Text {
                        id: planText
                        anchors.centerIn: parent
                        color: "#bfc7ce"
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        text: full.planLabel
                    }
                }

                PlasmaComponents.ToolButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    enabled: !full.loading
                    display: PlasmaComponents.AbstractButton.IconOnly
                    icon.name: "view-refresh"
                    onClicked: full.refreshRequested()

                    PlasmaComponents.ToolTip {
                        text: qsTr("Actualiser")
                    }
                }
            }

            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 146
                Layout.preferredHeight: 146

                ProgressRing {
                    anchors.fill: parent
                    value: full.remainingPercent
                    lineWidth: 8
                    centerFontSize: 15
                    centerText: full.loading ? "…" : full.errorMessage.length > 0 ? "!" : Math.round(value) + "%"
                    subText: full.errorMessage.length > 0 ? qsTr("indisponible") : qsTr("restant")
                    progressColor: full.errorMessage.length > 0 ? "#e06c75" : full.accentColor
                    textColor: "#f2f3f4"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                MetricRow {
                    Layout.fillWidth: true
                    accented: true
                    accentColor: full.accentColor
                    label: qsTr("Remise à zéro")
                    value: full.weeklyResetText.length > 0 ? full.weeklyResetText : "—"
                }

                MetricRow {
                    Layout.fillWidth: true
                    label: qsTr("Resets en stock")
                    value: String(full.resetCreditsAvailable)
                }

                MetricRow {
                    visible: full.resetCreditExpiryText.length > 0
                    Layout.fillWidth: true
                    label: qsTr("À utiliser avant")
                    value: full.resetCreditExpiryText
                }
            }

            Text {
                Layout.fillWidth: true
                color: full.errorMessage.length > 0 ? "#ef9a9a" : "#7f8991"
                elide: Text.ElideRight
                font.pixelSize: 9
                horizontalAlignment: Text.AlignHCenter
                text: full.errorMessage.length > 0 ? full.errorMessage : full.lastUpdatedText
            }
        }
    }
}

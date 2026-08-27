pragma ComponentBehavior: Bound

import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    property real remainingPercent: 0
    property string planLabel: ""
    property string weeklyResetText: ""
    property bool loading: false
    property string errorMessage: ""
    property string lastUpdatedText: ""
    property int resetCreditsAvailable: 0
    property string resetCreditExpiryText: ""
    property string activeCommand: ""

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.icon: "applications-development"
    Plasmoid.title: qsTr("Codex Usage")

    toolTipMainText: qsTr("Codex Usage")
    toolTipSubText: errorMessage.length > 0
        ? errorMessage
        : qsTr("%1 % restant · %2").arg(Math.round(remainingPercent)).arg(weeklyResetText)

    compactRepresentation: CompactRepresentation {
        remainingPercent: root.remainingPercent
        loading: root.loading
        errorMessage: root.errorMessage
        horizontalPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
        onActivated: {
            root.expanded = !root.expanded
            if (root.expanded) {
                root.refresh()
            }
        }
    }

    fullRepresentation: FullRepresentation {
        remainingPercent: root.remainingPercent
        planLabel: root.planLabel
        weeklyResetText: root.weeklyResetText
        loading: root.loading
        errorMessage: root.errorMessage
        lastUpdatedText: root.lastUpdatedText
        resetCreditsAvailable: root.resetCreditsAvailable
        resetCreditExpiryText: root.resetCreditExpiryText
        onRefreshRequested: root.refresh()
    }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"

        onNewData: (sourceName, data) => {
            if (sourceName !== root.activeCommand) {
                return
            }

            disconnectSource(sourceName)
            root.loading = false

            const output = data.stdout || ""
            try {
                const payload = JSON.parse(output.trim())
                if (!payload.ok) {
                    root.errorMessage = payload.error || qsTr("Données Codex indisponibles")
                    return
                }
                root.applyPayload(payload)
            } catch (error) {
                root.errorMessage = qsTr("Réponse Codex illisible")
            }
        }
    }

    Timer {
        interval: 10 * 60 * 1000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()

    function shellQuote(value) {
        return "'" + value.replace(/'/g, "'\\''") + "'"
    }

    function helperPath() {
        const url = Qt.resolvedUrl("../code/codex_usage.py").toString()
        return decodeURIComponent(url.replace(/^file:\/\//, ""))
    }

    function refresh() {
        if (loading) {
            return
        }

        if (activeCommand.length > 0) {
            executable.disconnectSource(activeCommand)
        }

        loading = true
        errorMessage = ""
        activeCommand = "python3 " + shellQuote(helperPath()) + " --request-id " + Date.now()
        executable.connectSource(activeCommand)
    }

    function findLimit(payload, id) {
        for (let index = 0; index < payload.limits.length; index++) {
            if (payload.limits[index].id === id) {
                return payload.limits[index]
            }
        }
        return null
    }

    function resetLabel(timestamp) {
        if (!timestamp) {
            return ""
        }
        const date = new Date(timestamp * 1000)
        return date.toLocaleString(Qt.locale(), "ddd HH:mm")
    }

    function deadlineLabel(timestamp) {
        if (!timestamp) {
            return ""
        }
        const date = new Date(timestamp * 1000)
        return date.toLocaleString(Qt.locale(), "d MMM HH:mm")
    }

    function applyPayload(payload) {
        const general = findLimit(payload, "codex") || payload.limits[0]
        const primary = general.primary || general.secondary

        remainingPercent = primary.remainingPercent
        weeklyResetText = resetLabel(primary.resetsAt)
        planLabel = general.planType ? general.planType.toUpperCase() : ""
        resetCreditsAvailable = payload.resetCreditsAvailable || 0
        resetCreditExpiryText = deadlineLabel(payload.nextResetCreditExpiresAt)
        errorMessage = ""

        const updated = new Date(payload.updatedAt * 1000)
        lastUpdatedText = qsTr("Actualisé à %1").arg(updated.toLocaleTimeString(Qt.locale(), "HH:mm"))
    }
}

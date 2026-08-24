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
    property bool sparkAvailable: false
    property real sparkFiveHourRemaining: 0
    property real sparkWeeklyRemaining: 0
    property string sparkFiveHourResetText: ""
    property string sparkWeeklyResetText: ""
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
        sparkAvailable: root.sparkAvailable
        sparkFiveHourRemaining: root.sparkFiveHourRemaining
        sparkWeeklyRemaining: root.sparkWeeklyRemaining
        sparkFiveHourResetText: root.sparkFiveHourResetText
        sparkWeeklyResetText: root.sparkWeeklyResetText
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

    function applyPayload(payload) {
        const general = findLimit(payload, "codex") || payload.limits[0]
        const primary = general.primary || general.secondary

        remainingPercent = primary.remainingPercent
        weeklyResetText = resetLabel(primary.resetsAt)
        planLabel = general.planType ? general.planType.toUpperCase() : ""
        resetCreditsAvailable = payload.resetCreditsAvailable || 0
        errorMessage = ""

        const spark = findLimit(payload, "codex_bengalfox")
        sparkAvailable = spark !== null
        if (spark) {
            const fiveHour = spark.primary
            const weekly = spark.secondary
            sparkFiveHourRemaining = fiveHour ? fiveHour.remainingPercent : 0
            sparkWeeklyRemaining = weekly ? weekly.remainingPercent : 0
            sparkFiveHourResetText = fiveHour ? resetLabel(fiveHour.resetsAt) : ""
            sparkWeeklyResetText = weekly ? resetLabel(weekly.resetsAt) : ""
        }

        const updated = new Date(payload.updatedAt * 1000)
        lastUpdatedText = qsTr("Actualisé à %1").arg(updated.toLocaleTimeString(Qt.locale(), "HH:mm"))
    }
}

import Quickshell
import Quickshell.Services.UPower
import QtQuick

Scope {
    id: root

    property var dev: UPower.displayDevice
    property int pct: Math.round(dev.percentage * 100)
    property bool charging: dev.state === UPowerDeviceState.Charging
    property bool warned: false

    function batIcon() {
        if (charging) return "󰂄"
        const icons = ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
        return icons[Math.min(9, Math.floor(pct / 10))]
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // run a command when the battery gets low
    Connections {
        target: root.dev

        function onPercentageChanged() {
            const discharging = root.dev.state === UPowerDeviceState.Discharging

            if (discharging && root.pct <= 10 && !root.warned) {
                root.warned = true
                Quickshell.execDetached([
                    "notify-send", "-u", "critical",
                    "Battery low", root.pct + "% left"
                ])
            }
            if (root.charging || root.pct > 20) root.warned = false
        }
    }

    PanelWindow {
        anchors { top: true; left: true; right: true }
        implicitHeight: 30
        color: "black"

        // center: time
        Text {
            anchors.centerIn: parent
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: "white"
        }
	Text {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: root.batIcon() + " " + root.pct + "%"
            color: "white"
        }
    }
}

import Quickshell
import QtQuick
import Quickshell.Services.UPower
import Quickshell.Networking

PanelWindow {
  anchors { top: true; left: true; right: true }
  margins { top: 3; left: 3; right: 3 }
  color: "black"
  implicitHeight: 30

  Scope {
    id: network
    property bool not_connected: Networking.connectivity != NetworkConnectivity.Full
    property var wired: Networking.devices.values.find(d => d.type === DeviceType.Wired)
    property bool cableIn: wired.hasLink
    property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi)
    property var active: wifi.networks.values.find(n => n.connected)
    property int signal: active.signalStrength * 10

    function icon() {
      if (not_connected) return "󰤭"
      if (cableIn) return ""
      const icons = ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]
      return icons[Math.floor(signal / 2)]
    }
  }

  Scope {
    id: bat
    property var dev: UPower.displayDevice
    property int pct: dev.percentage * 100
    property bool charging: dev.state === UPowerDeviceState.Charging

    function icon() {
      if (charging) return "󰂄"
      const icons = ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
      return icons[Math.min(9, Math.floor(pct / 10))]
    }
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  Text {
    anchors.centerIn: parent
    text: Qt.formatDateTime(clock.date, "HH:mm")
    color: "white"
  }

  Text {
    anchors.right: parent.right
    anchors.rightMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    text: bat.icon() + " " + bat.pct + "%"
    color: "white"
  }

  
  Text {
    text: network.icon()
    anchors.right: parent.right
    anchors.rightMargin: 67
    anchors.verticalCenter: parent.verticalCenter
    color: "white"
  }
}

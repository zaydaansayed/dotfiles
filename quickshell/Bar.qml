import Quickshell
import QtQuick
import Quickshell.Services.UPower
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Hyprland
import QtQuick.Controls

PanelWindow {
  anchors { top: true; left: true; right: true }
  margins { top: 3; left: 3; right: 3 }
  color: "black"
  implicitHeight: 30

  Scope {
    id: miscellaneous
    property bool bt_paired: Bluetooth.devices.values.some(d => d.connected)
    property int focus_workspace: Hyprland.focusedWorkspace.id
  }

  Scope {
    id: net
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

  Row { 
    anchors.verticalCenter: parent.verticalCenter
  
  Row {
    spacing: 3

    Repeater {
      model: 5

      Button {
	id: btn
        required property int index
        property int ws: index + 1
        property bool focusedWs: miscellaneous.focus_workspace === ws

        onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + ws + " })")

        background: Rectangle {
          radius: 4
          color: btn.focusedWs ? "#000000" : "#ffffff"
        }

        contentItem: Text {
          text: btn.ws
          color: btn.focusedWs ? "#ffffff" : "#000000"
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
        }
      }
    }

    Repeater {
      model: Hyprland.workspaces

      Button {
        id: extra
        required property var modelData
        property bool focusedWs: miscellaneous.focus_workspace === modelData.id

        visible: modelData.id > 5
        onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + modelData.id + " })")

        background: Rectangle {
          radius: 4
          color: extra.focusedWs ? "#000000" : "#ffffff"
        }

        contentItem: Text {
          text: extra.modelData.id
          color: extra.focusedWs ? "#ffffff" : "#000000"
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
        }
      }
    }}

  Text {
    text: Qt.formatDateTime(clock.date, "HH:mm")
    color: "white"
  }    

  }

  Text {
    anchors.centerIn: parent
    text: Qt.formatDateTime(clock.date, "HH:mm")
    color: "white"
  }

  Row {
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.rightMargin: 10
    spacing: 7

    Text {
	text: miscellaneous.bt_paired ? "󰂱" : ""
        color: "white"
    }

    Text {
        text: net.icon()
        color: "white"
    }

    Text {
        text: bat.icon() + " " + bat.pct + "%"
        color: "white"
    }
  }
}

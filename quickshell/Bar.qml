import Quickshell
import QtQuick
import Quickshell.Services.UPower
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Hyprland
import QtQuick.Controls
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Io

PanelWindow {
  anchors { top: true; left: true; right: true }
  margins { top: 3; left: 3; right: 3 }
  color: "black"
  implicitHeight: 30

  Scope {
    id: miscellaneous
    property bool bt_paired: Bluetooth.devices.values.some(d => d.connected)
    property int focus_workspace: Hyprland.focusedWorkspace.id
    property var player: Mpris.players.values.find(p => p.dbusName.toLowerCase().includes("spotify")) || null
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
    spacing: 6
  
  Row {
    anchors.verticalCenter: parent.verticalCenter
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
      }
    }

    Button {
      enabled: miscellaneous.player ? miscellaneous.player.canControl : false
      onClicked: miscellaneous.player.togglePlaying()
      visible: miscellaneous.player !== null && miscellaneous.player.canControl

      background: Rectangle {
        radius: 4
        color: parent.hovered ? "#333333" : "transparent"
      }
      contentItem: Text {
        text: miscellaneous.player && miscellaneous.player.isPlaying ? "󰏤" : "󰐊"
        color: "white"
      }
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      color: "white"
      width: Math.min(implicitWidth, 560)
      elide: Text.ElideRight
      text: miscellaneous.player ? (miscellaneous.player.trackArtist ? miscellaneous.player.trackArtist + " - " : "") + miscellaneous.player.trackTitle : ""
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
    spacing: 13
    Row {
      spacing: 7 
      Row {
        id: brightness
        spacing: 7
        HoverHandler { id: brig_hover }

        Text { 
          text: Shared.brig_icon()
          color: "white" 
        }

        PopupWindow {
          anchor.item: brightness
          anchor.edges: Edges.Bottom
          anchor.gravity: Edges.Bottom
          visible: brig_hover.hovered
          color: "transparent"
          implicitWidth: brig_tip.implicitWidth + 16
          implicitHeight: brig_tip.implicitHeight + 8

          Rectangle {
            anchors.fill: parent
            radius: 4
            color: "#222222"

            Text {
              id: brig_tip
              anchors.centerIn: parent
              color: "white"
              text: "Brightness: " + Shared.brig_num + "%"
            }
          }
        }

        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: brig_hover.hovered ? 60 : 0
          visible: width > 0
          height: 4
          radius: 2
          color: "#444444"
          Behavior on width { NumberAnimation { duration: 150 } }

          Rectangle {
            width: Shared.brig_num / 100 * parent.width
            height: parent.height
            radius: 2
          }
        }
      }

      Row {
        id: volume
        spacing: 7
        HoverHandler { id: vol_hover }

        Text { 
          text: Shared.audio_icon()
          color: "white" 
        }

        PopupWindow {
          anchor.item: volume
          anchor.edges: Edges.Bottom
          anchor.gravity: Edges.Bottom
          visible: vol_hover.hovered
          color: "transparent"
          implicitWidth: vol_tip.implicitWidth + 16
          implicitHeight: vol_tip.implicitHeight + 8

          Rectangle {
            anchors.fill: parent
            radius: 4
            color: "#222222"

            Text {
              id: vol_tip
              anchors.centerIn: parent
              color: "white"
              text: "Volume: " + Shared.audio_vol + "%" + (Shared.audio_muted ? " (muted)" : "")
            }
          }
        }

        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: vol_hover.hovered ? 60 : 0
          visible: width > 0
          height: 4
          radius: 2
          color: "#444444"
          Behavior on width { NumberAnimation { duration: 150 } }

          Rectangle {
            width: Shared.audio_vol / 100 * parent.width
            height: parent.height
            radius: 2
            color: Shared.audio_muted ? "#888888" : "white"
          }
        }
      }
    }
    Row {
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
}

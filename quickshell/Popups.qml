import Quickshell
import QtQuick

Scope {
  function showVol() {
    volWin.visible = true
    volTimer.restart()
  }
  function hideVol() {
    volTimer.stop()
    volWin.visible = false
  }
  function showBrig() {
    brigWin.visible = true
    brigTimer.restart()
  }
  function hideBrig() {
    brigTimer.stop()
    brigWin.visible = false
  }

  Timer { id: volTimer;  interval: 1500; onTriggered: volWin.visible = false }
  Timer { id: brigTimer; interval: 1500; onTriggered: brigWin.visible = false }

  PanelWindow {
    id: volWin
    visible: false
    implicitWidth: vol_row.width + 24
    implicitHeight: vol_row.height + 24
    anchors.bottom: true
    exclusionMode: ExclusionMode.Ignore
    color: "black"

    Row {
      id: vol_row
      anchors.centerIn: parent
      anchors.margins: 12
      spacing: 7        
      Text { 
        text: Shared.audio_icon()
        color: "white" 
      } 

      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 60
        height: 4
        radius: 2
        color: "#444444"

        Rectangle {
          width: Shared.audio_vol / 100 * parent.width
          height: parent.height
          radius: 2
          color: Shared.audio_muted ? "#888888" : "white"
        }
      }
    }
  }

  PanelWindow {
    id: brigWin
    visible: false
    implicitWidth: brig_row.width + 24
    implicitHeight: brig_row.height + 24
    anchors.bottom: true
    exclusionMode: ExclusionMode.Ignore
    color: "black"

    Row {
      id: brig_row
      anchors.centerIn: parent
      anchors.margins: 12
      spacing: 7
      Text { 
        text: Shared.brig_icon()
         color: "white" 
      } 

      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 60
        height: 4
        radius: 2
        color: "#444444"

        Rectangle {
          width: Shared.brig_num / 100 * parent.width
          height: parent.height
          radius: 2
          color: "white"
        }
      }
    }
  }
}

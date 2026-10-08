import Quickshell
import QtQuick
import Quickshell.Services.Notifications

Scope {
	function showVol() {
		volWin.visible = true
		volTimer.restart()
	}
	function showBrig() {
		brigWin.visible = true
		brigTimer.restart()
	}
	Timer { id: volTimer;  interval: 3000; onTriggered: volWin.visible = false }
	Timer { id: brigTimer; interval: 3000; onTriggered: brigWin.visible = false }

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

	NotificationServer {
		id: notif_server
		bodySupported: true
		onNotification: notif => {
			console.log("Received notification:", notif.summary, notif.body)
			notif.tracked = true
		}
	}

	PanelWindow {
		anchors { right: true; top: true }
		margins { right: 3; top: 3 }
		color: "transparent"
		visible: notif_server.trackedNotifications.values.length > 0
		implicitHeight: notifList.contentHeight

		ListView {
			id: notifList			
			anchors.fill: parent
			model: notif_server.trackedNotifications
			spacing: 6

			delegate: Rectangle {
				required property var modelData

				width: notifList.width
				height: notificationContent.implicitHeight
				color: "black"

				Timer {
					interval: 5000
					running: true
					onTriggered: modelData.expire()
				}

				Column {
					id: notificationContent
					anchors.fill: parent
					spacing: 4

					Text {
						width: notificationContent.width
						text: modelData.summary
						color: "white"
						wrapMode: Text.WordWrap
					}

					Text {
						width: notificationContent.width
						text: modelData.body
						color: "white"
						wrapMode: Text.WordWrap
						visible: text.length > 0
					}
				}

				MouseArea {
					anchors.fill: parent
					onClicked: modelData.dismiss()
				}
			}


		}
	}
}

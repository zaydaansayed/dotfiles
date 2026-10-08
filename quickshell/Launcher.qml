import Quickshell
import QtQuick
import QtQuick.Controls
import Quickshell.Wayland

PanelWindow {
	id: win
	signal closeRequested()

	exclusionMode: ExclusionMode.Ignore
	WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

	implicitWidth: 400
	implicitHeight: 500
	color: "black"

	function launch(entry) {
		if (!entry) return
		if (entry.runInTerminal)
		Quickshell.execDetached(["kitty", "-e", ...entry.command])
		else
		entry.execute()
		closeRequested()
	}

	ScriptModel {
		id: results
		values: DesktopEntries.applications.values
		.filter(a => !a.noDisplay && a.name.toLowerCase().includes(search.text.toLowerCase()))
		.sort((a, b) => a.name.localeCompare(b.name))
	}

	Column {
		anchors.fill: parent

		TextField {
			id: search
			width: parent.width
			placeholderText: "Search..."
			focus: true

			onTextChanged: list.currentIndex = 0
			onAccepted: win.launch(results.values[list.currentIndex])
			Keys.onEscapePressed: win.closeRequested()
			Keys.onDownPressed: list.incrementCurrentIndex()
			Keys.onUpPressed: list.decrementCurrentIndex()
		}

		ListView {
			id: list
			width: parent.width
			height: parent.height - search.height
			clip: true
			model: results

			delegate: Rectangle {
				required property var modelData
				height: 28
				width: ListView.view.width
				color: ListView.isCurrentItem ? "#555555" : "transparent"

				Text {
					text: modelData.name
					color: "white"
					height: 28
					verticalAlignment: Text.AlignVCenter
				}

				MouseArea {
					anchors.fill: parent
					hoverEnabled: true
					onClicked: win.launch(modelData)
				}
			}
		}
	}
}

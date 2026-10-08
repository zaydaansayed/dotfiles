pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import Quickshell.Services.Pipewire

Singleton {
	property int brig_num: 0

	Process {
		command: ["sh", Quickshell.env("HOME") + "/dotfiles/quickshell/scripts/brightness.sh"]
		running: true

		stdout: SplitParser {
			onRead: data => {
				const n = parseInt(data)
				if (!isNaN(n)) brig_num = n
			}
		}
	}

	function brig_icon() {
		const icons = ["󰃞", "󰃝", "󰃟", "󰃠"]
		return icons[Math.floor(brig_num / 25)]
	}

	property var audio_sink: Pipewire.defaultAudioSink
	PwObjectTracker { objects: [ audio_sink ] }
	property int audio_vol: audio_sink.audio.volume * 100
	property bool audio_muted: audio_sink.audio.muted

	function audio_icon() {
		if (audio_muted) return ""
		const icons = ["", "", ""]
		return icons[Math.floor(audio_vol / 33.34)]
	}
}

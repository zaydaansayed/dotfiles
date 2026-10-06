import Quickshell
import Quickshell.Io

ShellRoot {
  Variants {
    model: Quickshell.screens

    Bar {
      required property var modelData
      screen: modelData
    }
  }

  Popups { id: popups }

  IpcHandler {
    target: "popups"
    function vol(): void { popups.showVol() }
    function brig(): void { popups.showBrig() }
  }

  LazyLoader {
    id: launcherLoader
    active: false

    Launcher {
      onCloseRequested: launcherLoader.active = false
    }
  }

  IpcHandler {
    target: "launcher"
    function open(): void { launcherLoader.active = true }
  }
}

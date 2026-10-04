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

    LazyLoader {
        id: launcherLoader
        active: false

        Launcher {
            onCloseRequested: launcherLoader.active = false
        }
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { launcherLoader.active = !launcherLoader.active }
    }
}

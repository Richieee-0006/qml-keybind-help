pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../services" as QsServices

Singleton {
    id: root

    readonly property string configPath: {
        const home = Quickshell.env("HOME")
        const xdg = Quickshell.env("XDG_CONFIG_HOME")
        const cfgHome = (xdg && xdg.length > 0) ? xdg : `${home}/.config`
        return `${cfgHome}/qml-keybind-help/config.json`
    }

    Component.onCompleted: file.reload()

    property var data: ({})

    function _expandHome(p) {
        if (!p || typeof p !== "string") return p
        if (p.startsWith("~/")) return `${Quickshell.env("HOME")}/${p.slice(2)}`
        return p
    }

    readonly property var appearance: ({
        fontFamily: data.appearance?.fontFamily ?? "Inter",
        materialIconFont: data.appearance?.materialIconFont ?? "Material Design Icons",
        theme: data.appearance?.theme ?? "auto"
    })

    readonly property var paths: ({
        caelestiaScheme: _expandHome(data.paths?.caelestiaScheme ?? "~/.local/state/caelestia/scheme.json"),
        pywalColors: _expandHome(data.paths?.pywalColors ?? "~/.cache/wal/colors.json"),
        pywalBarColors: _expandHome(data.paths?.pywalBarColors ?? "~/.cache/wal/colors-bar.json"),
        pywalDockColors: _expandHome(data.paths?.pywalDockColors ?? "~/.cache/wal/colors-dock.json")
    })

    readonly property var keybindhelp: ({
        hyprConfigDir: _expandHome(data.keybindhelp?.hyprConfigDir ?? "~/.config/hypr")
    })

    readonly property AppearanceConfig appearanceTokens: AppearanceConfig {}

    FileView {
        id: file
        path: root.configPath
        watchChanges: true

        onLoaded: {
            try {
                root.data = JSON.parse(text())
                QsServices.Logger.debug("Config", "config.json loaded")
            } catch (e) {
                QsServices.Logger.warn("Config", `Failed to parse config.json: ${e?.message ?? e}`)
            }
        }

        onFileChanged: file.reload()

        onLoadFailed: err => {
            if (err !== FileViewError.FileNotFound)
                QsServices.Logger.warn("Config", `Failed to read config.json: ${FileViewError.toString(err)}`)
        }
    }
}

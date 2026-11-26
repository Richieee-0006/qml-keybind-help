pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick 6.10
import "../config" as QsConfig
import "." as QsServices
import "ThemePresets.js" as Presets

Singleton {
    id: root

    // Theme mode: "auto" (Caelestia -> Pywal -> Catppuccin Mocha) or a preset id
    property string themeOverride: ""
    readonly property string configuredTheme: QsConfig.Config.appearance.theme || "auto"
    readonly property string activeThemeId: themeOverride.length > 0 ? themeOverride : configuredTheme

    // Raw cached payloads for live switching back to "auto" without re-reading disk
    property var caelestiaData: null
    property var pywalData: null

    property string activeSource: "preset" // "caelestia" | "pywal" | "preset"
    property string schemeName: "Catppuccin Mocha"
    property bool isLight: false

    readonly property string autoSourceLabel: {
        if (activeSource === "caelestia") return "Caelestia"
        if (activeSource === "pywal") return "Pywal"
        return "Mocha"
    }

    readonly property string activeThemeLabel: Presets.labelFor(activeThemeId, autoSourceLabel)

    // === Core Material 3 Palette Tokens (Caelestia-compatible) ===
    property color background: "#111218"
    property color foreground: "#e5e5e6"
    property color cursor: "#e5e5e6"

    property color surface: "#111218"
    property color surfaceDim: "#0d0d12"
    property color surfaceBright: "#2e3042"
    property color surfaceContainerLowest: "#0a0b0f"
    property color surfaceContainerLow: "#15161e"
    property color surfaceContainer: "#191a24"
    property color surfaceContainerHigh: "#212330"
    property color surfaceContainerHighest: "#2a2c3c"

    property color m3onSurface: "#e5e5e6"
    property color m3onSurfaceVariant: "#c6c6c7"
    readonly property color m3onSurfaceMuted: Qt.rgba(m3onSurfaceVariant.r, m3onSurfaceVariant.g, m3onSurfaceVariant.b, isLight ? 0.88 : 0.78)
    readonly property color onSurface: m3onSurface
    readonly property color onSurfaceVariant: m3onSurfaceVariant
    readonly property color onSurfaceMuted: m3onSurfaceMuted

    property color outline: "#8e8e90"
    property color outlineVariant: "#42444d"

    property color primary: "#9db0e6"
    property color m3onPrimary: "#122149"
    property color primaryContainer: "#1d3372"
    property color m3onPrimaryContainer: "#d6def5"
    readonly property color onPrimary: m3onPrimary
    readonly property color onPrimaryContainer: m3onPrimaryContainer

    property color secondary: "#c0aada"
    property color m3onSecondary: "#2c1c40"
    property color secondaryContainer: "#452b63"
    property color m3onSecondaryContainer: "#e5dcef"
    readonly property color onSecondary: m3onSecondary
    readonly property color onSecondaryContainer: m3onSecondaryContainer

    property color tertiary: "#debea6"
    property color m3onTertiary: "#432b19"
    property color tertiaryContainer: "#684327"
    property color m3onTertiaryContainer: "#f1e4da"
    readonly property color onTertiary: m3onTertiary
    readonly property color onTertiaryContainer: m3onTertiaryContainer

    property color success: "#a2ebbd"
    property color m3onSuccess: "#104c26"
    property color warning: "#f3c568"
    property color m3onWarning: "#2d2006"
    property color error: "#f2a19b"
    property color m3onError: "#520f0a"
    readonly property color onSuccess: m3onSuccess
    readonly property color onWarning: m3onWarning
    readonly property color onError: m3onError
    readonly property color info: primary

    property color shadow: "#000000"
    property color scrim: "#000000"

    // Legacy terminal color slots kept synced for full compatibility
    property color color0: "#0e0f14"
    property color color1: "#eb6960"
    property color color2: "#68df93"
    property color color3: "#f3c568"
    property color color4: "#7094db"
    property color color5: "#996ce0"
    property color color6: "#e0966c"
    property color color7: "#cacbce"
    property color color8: "#646e90"
    property color color9: "#f2857d"
    property color color10: "#81e9a7"
    property color color11: "#f7d287"
    property color color12: "#8da9e2"
    property color color13: "#ac86ea"
    property color color14: "#eaaa86"
    property color color15: "#f5f5f5"

    // Compatibility aliases
    readonly property color glassLow: surfaceContainerLow
    readonly property color glassHigh: surfaceContainerHigh
    readonly property color glassHighest: surfaceContainerHighest
    readonly property color glassBorder: outlineVariant
    readonly property color glassBorderStrong: Qt.rgba(primary.r, primary.g, primary.b, 0.32)
    readonly property color stateLayerLight: Qt.rgba(foreground.r, foreground.g, foreground.b, 1)
    readonly property color stateLayerDark: Qt.rgba(background.r, background.g, background.b, 1)
    readonly property color inverseSurface: foreground
    readonly property color inverseOnSurface: background
    readonly property color inversePrimary: Qt.lighter(primary, 1.35)

    function _hex(val, fallback) {
        if (!val || typeof val !== "string") return fallback
        return val.startsWith("#") ? val : `#${val}`
    }

    function _applyPreset(presetId) {
        const p = Presets.getPreset(presetId)
        root.activeSource = "preset"
        root.schemeName = p.label
        root.isLight = p.mode === "light"

        root.background = p.background
        root.foreground = p.onSurface
        root.cursor = p.primary
        root.surface = p.surface
        root.surfaceDim = p.surfaceDim
        root.surfaceBright = p.surfaceBright
        root.surfaceContainerLowest = p.surfaceContainerLowest
        root.surfaceContainerLow = p.surfaceContainerLow
        root.surfaceContainer = p.surfaceContainer
        root.surfaceContainerHigh = p.surfaceContainerHigh
        root.surfaceContainerHighest = p.surfaceContainerHighest
        root.m3onSurface = p.onSurface
        root.m3onSurfaceVariant = p.onSurfaceVariant
        root.outline = p.outline
        root.outlineVariant = p.outlineVariant

        root.primary = p.primary
        root.m3onPrimary = p.onPrimary
        root.primaryContainer = p.primaryContainer
        root.m3onPrimaryContainer = p.onPrimaryContainer
        root.secondary = p.secondary
        root.m3onSecondary = p.onSecondary
        root.secondaryContainer = p.secondaryContainer
        root.m3onSecondaryContainer = p.onSecondaryContainer
        root.tertiary = p.tertiary
        root.m3onTertiary = p.onTertiary
        root.tertiaryContainer = p.tertiaryContainer
        root.m3onTertiaryContainer = p.onTertiaryContainer

        root.success = p.success
        root.m3onSuccess = p.onSuccess
        root.warning = p.warning
        root.m3onWarning = p.onWarning
        root.error = p.error
        root.m3onError = p.onError
        root.shadow = p.shadow
        root.scrim = p.scrim

        root.color0 = p.surfaceContainerLowest
        root.color1 = p.error
        root.color2 = p.success
        root.color3 = p.warning
        root.color4 = p.primary
        root.color5 = p.secondary
        root.color6 = p.tertiary
        root.color7 = p.onSurface
        root.color8 = p.outline
    }

    function _applyCaelestia(data) {
        const c = data && data.colours ? data.colours : null
        if (!c) return false

        root.activeSource = "caelestia"
        root.schemeName = data.name || "Caelestia"
        root.isLight = data.mode === "light"

        root.background = _hex(c.background, root.background)
        root.foreground = _hex(c.onSurface || c.onBackground, root.foreground)
        root.cursor = _hex(c.primary, root.cursor)

        root.surface = _hex(c.surface || c.background, root.surface)
        root.surfaceDim = _hex(c.surfaceDim, root.surfaceDim)
        root.surfaceBright = _hex(c.surfaceBright, root.surfaceBright)
        root.surfaceContainerLowest = _hex(c.surfaceContainerLowest, root.surfaceContainerLowest)
        root.surfaceContainerLow = _hex(c.surfaceContainerLow, root.surfaceContainerLow)
        root.surfaceContainer = _hex(c.surfaceContainer, root.surfaceContainer)
        root.surfaceContainerHigh = _hex(c.surfaceContainerHigh, root.surfaceContainerHigh)
        root.surfaceContainerHighest = _hex(c.surfaceContainerHighest, root.surfaceContainerHighest)

        root.m3onSurface = _hex(c.onSurface, root.m3onSurface)
        root.m3onSurfaceVariant = _hex(c.onSurfaceVariant, root.m3onSurfaceVariant)
        root.outline = _hex(c.outline, root.outline)
        root.outlineVariant = _hex(c.outlineVariant, root.outlineVariant)

        root.primary = _hex(c.primary, root.primary)
        root.m3onPrimary = _hex(c.onPrimary, root.m3onPrimary)
        root.primaryContainer = _hex(c.primaryContainer, root.primaryContainer)
        root.m3onPrimaryContainer = _hex(c.onPrimaryContainer, root.m3onPrimaryContainer)

        root.secondary = _hex(c.secondary, root.secondary)
        root.m3onSecondary = _hex(c.onSecondary, root.m3onSecondary)
        root.secondaryContainer = _hex(c.secondaryContainer, root.secondaryContainer)
        root.m3onSecondaryContainer = _hex(c.onSecondaryContainer, root.m3onSecondaryContainer)

        root.tertiary = _hex(c.tertiary, root.tertiary)
        root.m3onTertiary = _hex(c.onTertiary, root.m3onTertiary)
        root.tertiaryContainer = _hex(c.tertiaryContainer, root.tertiaryContainer)
        root.m3onTertiaryContainer = _hex(c.onTertiaryContainer, root.m3onTertiaryContainer)

        root.success = _hex(c.success || c.term2, root.success)
        root.m3onSuccess = _hex(c.onSuccess, root.m3onSuccess)
        root.warning = _hex(c.term3 || c.tertiary, root.warning)
        root.m3onWarning = root.isLight ? "#ffffff" : "#241900"
        root.error = _hex(c.error || c.term1, root.error)
        root.m3onError = _hex(c.onError, root.m3onError)
        root.shadow = _hex(c.shadow, "#000000")
        root.scrim = _hex(c.scrim, "#000000")

        if (c.term0) root.color0 = _hex(c.term0, root.color0)
        if (c.term1) root.color1 = _hex(c.term1, root.color1)
        if (c.term2) root.color2 = _hex(c.term2, root.color2)
        if (c.term3) root.color3 = _hex(c.term3, root.color3)
        if (c.term4) root.color4 = _hex(c.term4, root.color4)
        if (c.term5) root.color5 = _hex(c.term5, root.color5)
        if (c.term6) root.color6 = _hex(c.term6, root.color6)
        if (c.term7) root.color7 = _hex(c.term7, root.color7)
        if (c.term8) root.color8 = _hex(c.term8, root.color8)
        if (c.term9) root.color9 = _hex(c.term9, root.color9)
        if (c.term10) root.color10 = _hex(c.term10, root.color10)
        if (c.term11) root.color11 = _hex(c.term11, root.color11)
        if (c.term12) root.color12 = _hex(c.term12, root.color12)
        if (c.term13) root.color13 = _hex(c.term13, root.color13)
        if (c.term14) root.color14 = _hex(c.term14, root.color14)
        if (c.term15) root.color15 = _hex(c.term15, root.color15)
        return true
    }

    function _applyPywal(data) {
        if (!data || (!data.special && !data.colors)) return false
        root.activeSource = "pywal"
        root.schemeName = "Pywal"

        const bg = (data.special && data.special.background) ? Qt.color(data.special.background) : Qt.color("#111218")
        const fg = (data.special && data.special.foreground) ? Qt.color(data.special.foreground) : Qt.color("#e5e5e6")
        const cols = data.colors || {}
        const c1 = Qt.color(cols.color1 || "#eb6960")
        const c2 = Qt.color(cols.color2 || "#68df93")
        const c3 = Qt.color(cols.color3 || "#f3c568")
        const c4 = Qt.color(cols.color4 || "#7094db")
        const c5 = Qt.color(cols.color5 || "#996ce0")
        const c6 = Qt.color(cols.color6 || "#e0966c")
        const c8 = Qt.color(cols.color8 || "#646e90")

        const light = bg.hslLightness > 0.55
        root.isLight = light
        root.background = bg
        root.foreground = fg
        root.cursor = (data.special && data.special.cursor) ? data.special.cursor : c4

        root.surface = bg
        root.surfaceDim = light ? Qt.darker(bg, 1.08) : Qt.darker(bg, 1.15)
        root.surfaceBright = light ? Qt.lighter(bg, 1.05) : Qt.lighter(bg, 1.45)
        root.surfaceContainerLowest = light ? Qt.darker(bg, 1.04) : Qt.darker(bg, 1.20)
        root.surfaceContainerLow = light ? bg : Qt.lighter(bg, 1.12)
        root.surfaceContainer = light ? "#ffffff" : Qt.lighter(bg, 1.24)
        root.surfaceContainerHigh = light ? Qt.darker(bg, 1.05) : Qt.lighter(bg, 1.40)
        root.surfaceContainerHighest = light ? Qt.darker(bg, 1.10) : Qt.lighter(bg, 1.58)

        root.m3onSurface = fg
        root.m3onSurfaceVariant = Qt.rgba(fg.r, fg.g, fg.b, 0.78)
        root.outline = c8
        root.outlineVariant = Qt.rgba(c8.r, c8.g, c8.b, 0.50)

        root.primary = c4
        root.m3onPrimary = c4.hslLightness > 0.55 ? "#101828" : "#ffffff"
        root.primaryContainer = Qt.rgba(c4.r, c4.g, c4.b, light ? 0.16 : 0.24)
        root.m3onPrimaryContainer = light ? Qt.darker(c4, 1.6) : fg

        root.secondary = c5
        root.m3onSecondary = c5.hslLightness > 0.55 ? "#1a1028" : "#ffffff"
        root.secondaryContainer = Qt.rgba(c5.r, c5.g, c5.b, 0.22)
        root.m3onSecondaryContainer = fg

        root.tertiary = c6
        root.m3onTertiary = "#1f1208"
        root.tertiaryContainer = Qt.rgba(c6.r, c6.g, c6.b, 0.22)
        root.m3onTertiaryContainer = fg

        root.success = c2
        root.m3onSuccess = "#0e2616"
        root.warning = c3
        root.m3onWarning = "#241900"
        root.error = c1
        root.m3onError = "#ffffff"
        root.shadow = "#000000"
        root.scrim = "#000000"

        for (let i = 0; i <= 15; i++) {
            const key = `color${i}`
            if (cols[key]) root[key] = cols[key]
        }
        return true
    }

    function applyResolvedTheme(): void {
        const target = root.activeThemeId
        if (target && target !== "auto") {
            _applyPreset(target)
            return
        }
        if (root.caelestiaData && _applyCaelestia(root.caelestiaData)) return
        if (root.pywalData && _applyPywal(root.pywalData)) return
        _applyPreset("catppuccin-mocha")
    }

    function setTheme(themeId: string): void {
        const clean = (themeId || "auto").trim().toLowerCase()
        if (clean === "auto" || Presets.PRESETS[clean]) {
            root.themeOverride = clean
            root.applyResolvedTheme()
        }
    }

    function cycleTheme(): void {
        setTheme(Presets.nextThemeId(root.activeThemeId))
    }

    function reload(): void {
        caelestiaFile.reload()
        pywalFile.reload()
        pywalBarFile.reload()
        pywalDockFile.reload()
    }

    onConfiguredThemeChanged: applyResolvedTheme()
    Component.onCompleted: applyResolvedTheme()

    IpcHandler {
        target: "pywal"
        property string background: root.background.toString()
        property string foreground: root.foreground.toString()
        property string primary: root.primary.toString()
        property string barPrimary: root.bar.primary.toString()
        property string dockPrimary: root.dock.primary.toString()
        property string theme: root.activeThemeId
        property string source: root.activeSource

        function reload(): void {
            root.reload()
        }

        function setTheme(name: string): void {
            root.setTheme(name)
        }

        function paletteSummary(): string {
            return JSON.stringify({
                theme: root.activeThemeId,
                label: root.activeThemeLabel,
                source: root.activeSource,
                isLight: root.isLight,
                surface: root.surface.toString(),
                deck: root.surfaceContainerLowest.toString(),
                container: root.surfaceContainer.toString(),
                text: root.m3onSurface.toString(),
                primary: root.primary.toString(),
                primaryContainer: root.primaryContainer.toString(),
                onPrimaryContainer: root.m3onPrimaryContainer.toString()
            })
        }
    }

    // 1. Primary auto-theme source: Caelestia native M3 scheme.json
    FileView {
        id: caelestiaFile
        path: QsConfig.Config.paths.caelestiaScheme
        watchChanges: true
        printErrors: false
        onLoaded: {
            try {
                root.caelestiaData = JSON.parse(text())
                root.applyResolvedTheme()
                QsServices.Logger.info("Theme", `Caelestia scheme loaded (${root.caelestiaData.name || "default"}, ${root.caelestiaData.mode || "dark"})`)
            } catch (e) {
                QsServices.Logger.warn("Theme", `Failed to parse Caelestia scheme.json: ${e?.message ?? e}`)
            }
        }
        onFileChanged: caelestiaFile.reload()
        onLoadFailed: err => {
            root.caelestiaData = null
            root.applyResolvedTheme()
        }
    }

    // 2. Fallback auto-theme source: Pywal colors.json
    FileView {
        id: pywalFile
        path: QsConfig.Config.paths.pywalColors
        watchChanges: true
        printErrors: false
        onLoaded: {
            try {
                root.pywalData = JSON.parse(text())
                root.applyResolvedTheme()
            } catch (e) {
                QsServices.Logger.warn("Theme", `Failed to parse pywal colors.json: ${e?.message ?? e}`)
            }
        }
        onFileChanged: pywalFile.reload()
        onLoadFailed: err => {
            root.pywalData = null
            root.applyResolvedTheme()
        }
    }

    // Sub-palettes kept for compatibility
    readonly property PywalTheme bar: PywalTheme {
        id: barTheme
        fallback: root
    }

    readonly property PywalTheme dock: PywalTheme {
        id: dockTheme
        fallback: root
    }

    FileView {
        id: pywalBarFile
        path: QsConfig.Config.paths.pywalBarColors
        watchChanges: true
        printErrors: false
        onLoaded: barTheme.loadColors(text())
        onFileChanged: pywalBarFile.reload()
    }

    FileView {
        id: pywalDockFile
        path: QsConfig.Config.paths.pywalDockColors
        watchChanges: true
        printErrors: false
        onLoaded: dockTheme.loadColors(text())
        onFileChanged: pywalDockFile.reload()
    }
}

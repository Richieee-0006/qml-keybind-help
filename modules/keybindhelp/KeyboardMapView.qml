import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10 as QQC
import "KeyboardLayouts.js" as Layouts

ColumnLayout {
    id: kbRoot

    property var allBinds: []
    property var keyboardInfo: ({})
    property string searchQuery: ""
    property var liveMods: []

    property color cSurface: "#111218"
    property color cDeck: "#0a0b0f"
    property color cContainer: "#191a24"
    property color cContainerLow: "#15161e"
    property color cContainerHigh: "#212330"
    property color cPrimary: "#9db0e6"
    property color cOnPrimary: "#122149"
    property color cPrimaryContainer: "#1d3372"
    property color cOnPrimaryContainer: "#d6def5"
    property color cText: "#e5e5e6"
    property color cSubText: "#c6c6c7"
    property color cBorder: "#42444d"
    property color cWarning: "#f3c568"
    property color cOnWarning: "#241900"
    property color cSuccess: "#a2ebbd"
    property bool isLight: false
    property string fontFamily: "Inter"

    // Filter / view state
    property bool showAllLayers: false
    property string activeSubmap: ""
    property var manualMods: ["Super"]
    property bool heatmapMode: false

    // Selected / hovered physical key
    property string selectedKeyId: ""
    property string hoveredKeyId: ""

    // Hardware profile & layout overrides (empty = auto-detected)
    property string overrideProfile: ""
    property string overrideLayout: ""

    readonly property string activeProfile: overrideProfile.length > 0
        ? overrideProfile
        : (keyboardInfo.profile || "ideapad-gaming-3")

    readonly property string activeLayout: overrideLayout.length > 0
        ? overrideLayout
        : (keyboardInfo.layout || "cz")

    readonly property bool isLiveActive: liveMods && liveMods.length > 0
    readonly property var effectiveMods: isLiveActive ? liveMods : manualMods
    readonly property bool isSearching: searchQuery.trim().length > 0

    readonly property var layoutData: Layouts.buildLayout(activeProfile, activeLayout)

    readonly property var layerPresets: [
        { id: "all", label: "Vše", mods: [], submap: "", isAll: true },
        { id: "super", label: "Super", mods: ["Super"], submap: "", isAll: false },
        { id: "super+shift", label: "Super+Shift", mods: ["Super", "Shift"], submap: "", isAll: false },
        { id: "super+alt", label: "Super+Alt", mods: ["Super", "Alt"], submap: "", isAll: false },
        { id: "super+ctrl", label: "Super+Ctrl", mods: ["Super", "Ctrl"], submap: "", isAll: false },
        { id: "alt", label: "Alt", mods: ["Alt"], submap: "", isAll: false },
        { id: "resize", label: "Resize", mods: [], submap: "resize", isAll: false }
    ]

    function _sameMods(a, b) {
        if (!a || !b || a.length !== b.length) return false
        for (let i = 0; i < a.length; i++) {
            if (b.indexOf(a[i]) === -1) return false
        }
        return true
    }

    function _canonicalMods(list) {
        const order = ["Super", "Ctrl", "Alt", "Shift"]
        const out = []
        for (let i = 0; i < order.length; i++) {
            if (list.indexOf(order[i]) !== -1) out.push(order[i])
        }
        return out
    }

    function isPresetActive(preset) {
        if (isLiveActive) {
            return !preset.isAll && preset.submap === "" && _sameMods(liveMods, preset.mods)
        }
        if (preset.isAll) return showAllLayers && activeSubmap === ""
        if (preset.submap.length > 0) return activeSubmap === preset.submap
        return !showAllLayers && activeSubmap === "" && _sameMods(manualMods, preset.mods)
    }

    function selectPreset(preset) {
        if (preset.isAll) {
            showAllLayers = true
            activeSubmap = ""
            manualMods = []
        } else if (preset.submap.length > 0) {
            showAllLayers = false
            activeSubmap = preset.submap
            manualMods = []
        } else {
            showAllLayers = false
            activeSubmap = ""
            manualMods = preset.mods.slice()
        }
    }

    function toggleModifierKey(modName) {
        showAllLayers = false
        activeSubmap = ""
        const next = manualMods.slice()
        const idx = next.indexOf(modName)
        if (idx >= 0) next.splice(idx, 1)
        else next.push(modName)
        manualMods = _canonicalMods(next)
    }

    function cycleProfile() {
        const list = Layouts.PROFILES
        const idx = list.findIndex(p => p.id === activeProfile)
        overrideProfile = list[(idx + 1) % list.length].id
    }

    function toggleLayoutCode() {
        overrideLayout = activeLayout.toLowerCase().startsWith("cz") ? "us" : "cz"
    }

    function profileDisplayName() {
        if (overrideProfile.length === 0 && keyboardInfo.model && keyboardInfo.model.length > 0) {
            const m = keyboardInfo.model
            return m.length > 28 ? m.slice(0, 28) : m
        }
        const found = Layouts.PROFILES.find(p => p.id === activeProfile)
        return found ? found.label : activeProfile
    }

    // Build lookup index: keyId -> array of binds
    readonly property var bindsByKey: {
        const map = {}
        const q = searchQuery.trim().toLowerCase()
        for (let i = 0; i < allBinds.length; i++) {
            const b = allBinds[i]
            if (q.length > 0) {
                const hit = (b.key || "").toLowerCase().includes(q)
                    || (b.action || "").toLowerCase().includes(q)
                    || (b.cat || "").toLowerCase().includes(q)
                if (!hit) continue
            }
            const ks = b.keys || []
            for (let j = 0; j < ks.length; j++) {
                const kid = ks[j]
                if (!map[kid]) map[kid] = []
                map[kid].push(b)
            }
        }
        return map
    }

    function bindMatchesActiveLayer(b) {
        if (isSearching) return true
        if (isLiveActive) {
            return (b.submap || "") === "" && _sameMods(b.mods || [], liveMods)
        }
        if (activeSubmap.length > 0) {
            return (b.submap || "") === activeSubmap
        }
        if (showAllLayers) {
            return (b.submap || "") === ""
        }
        return (b.submap || "") === "" && _sameMods(b.mods || [], manualMods)
    }

    function allBindsForKeySpec(spec) {
        const out = []
        const seen = {}
        const ids = [spec.id].concat(spec.fnIds || [])
        for (let i = 0; i < ids.length; i++) {
            const arr = bindsByKey[ids[i]] || []
            for (let j = 0; j < arr.length; j++) {
                const b = arr[j]
                const sig = b.cat + "|" + b.key
                if (!seen[sig]) {
                    seen[sig] = true
                    out.push(b)
                }
            }
        }
        return out
    }

    function layerBindsForKeySpec(spec) {
        const all = allBindsForKeySpec(spec)
        const out = []
        for (let i = 0; i < all.length; i++) {
            if (bindMatchesActiveLayer(all[i])) out.push(all[i])
        }
        return out
    }

    function findKeySpec(keyId) {
        if (!keyId) return null
        const keys = layoutData.keys || []
        for (let i = 0; i < keys.length; i++) {
            if (keys[i].id === keyId) return keys[i]
        }
        for (let i = 0; i < Layouts.MOUSE_CONTROLS.length; i++) {
            if (Layouts.MOUSE_CONTROLS[i].id === keyId) return Layouts.MOUSE_CONTROLS[i]
        }
        return null
    }

    readonly property string inspectedKeyId: hoveredKeyId.length > 0 ? hoveredKeyId : selectedKeyId
    readonly property var inspectedSpec: findKeySpec(inspectedKeyId)
    readonly property var inspectedAllBinds: inspectedSpec ? allBindsForKeySpec(inspectedSpec) : []
    readonly property var inspectedLayerBinds: inspectedSpec ? layerBindsForKeySpec(inspectedSpec) : []

    // Summary stats for idle inspector state
    readonly property var layerStats: {
        let boundCount = 0
        let freeAlpha = 0
        const keys = layoutData.keys || []
        for (let i = 0; i < keys.length; i++) {
            const spec = keys[i]
            if (spec.mod) continue
            const matches = heatmapMode ? allBindsForKeySpec(spec) : layerBindsForKeySpec(spec)
            if (matches.length > 0) {
                boundCount++
            } else if (spec.id.length === 1 && spec.id >= "A" && spec.id <= "Z") {
                freeAlpha++
            }
        }
        return { bound: boundCount, freeAlpha: freeAlpha }
    }

    function activeLayerTitle() {
        if (isSearching) return `Hledání "${searchQuery.trim()}"`
        if (isLiveActive) return liveMods.join(" + ")
        if (activeSubmap.length > 0) return "Resize Mode"
        if (showAllLayers) return "Všechny vrstvy"
        if (manualMods.length === 0) return "Bez modifikátoru"
        return manualMods.join(" + ")
    }

    spacing: 10

    // =========================================================================
    // 1. TOP TOOLBAR: Layer Presets | Heatmap Toggle | Detected Hardware Pill
    // =========================================================================
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        // Layer preset pills
        Row {
            spacing: 4

            Repeater {
                model: kbRoot.layerPresets

                Rectangle {
                    id: presetPill
                    required property var modelData
                    readonly property bool active: kbRoot.isPresetActive(modelData)

                    height: 28
                    width: presetText.implicitWidth + 18
                    radius: 8
                    color: active
                        ? Qt.rgba(kbRoot.cPrimary.r, kbRoot.cPrimary.g, kbRoot.cPrimary.b, 0.22)
                        : presetHover.hovered
                            ? Qt.rgba(kbRoot.cText.r, kbRoot.cText.g, kbRoot.cText.b, 0.08)
                            : kbRoot.cContainer
                    border.width: 1
                    border.color: active
                        ? kbRoot.cPrimary
                        : Qt.rgba(kbRoot.cBorder.r, kbRoot.cBorder.g, kbRoot.cBorder.b, 0.35)

                    Behavior on color { ColorAnimation { duration: 110 } }

                    HoverHandler { id: presetHover }

                    Text {
                        id: presetText
                        anchors.centerIn: parent
                        text: presetPill.modelData.label
                        font.family: kbRoot.fontFamily
                        font.pixelSize: 11
                        font.weight: presetPill.active ? Font.DemiBold : Font.Normal
                        color: presetPill.active ? kbRoot.cPrimary : kbRoot.cText
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: kbRoot.selectPreset(presetPill.modelData)
                    }
                }
            }
        }

        // Live held-modifier badge
        Rectangle {
            visible: kbRoot.isLiveActive
            Layout.preferredHeight: 24
            Layout.preferredWidth: liveRow.implicitWidth + 14
            radius: 6
            color: Qt.rgba(kbRoot.cSuccess.r, kbRoot.cSuccess.g, kbRoot.cSuccess.b, 0.20)
            border.width: 1
            border.color: kbRoot.cSuccess

            Row {
                id: liveRow
                anchors.centerIn: parent
                spacing: 5
                Rectangle {
                    width: 6; height: 6; radius: 3
                    anchors.verticalCenter: parent.verticalCenter
                    color: kbRoot.cSuccess
                }
                Text {
                    text: "LIVE: " + kbRoot.liveMods.join("+")
                    font.family: kbRoot.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    color: kbRoot.cSuccess
                }
            }
        }

        Item { Layout.fillWidth: true }

        // Heatmap legend when active
        Row {
            visible: kbRoot.heatmapMode
            spacing: 8
            Layout.rightMargin: 4

            Repeater {
                model: [
                    { label: "Volné", color: Qt.rgba(kbRoot.cContainer.r, kbRoot.cContainer.g, kbRoot.cContainer.b, 1.0), border: kbRoot.cBorder },
                    { label: "1", color: Qt.rgba(kbRoot.cPrimary.r, kbRoot.cPrimary.g, kbRoot.cPrimary.b, 0.22), border: kbRoot.cPrimary },
                    { label: "2", color: Qt.rgba(kbRoot.cPrimary.r, kbRoot.cPrimary.g, kbRoot.cPrimary.b, 0.45), border: kbRoot.cPrimary },
                    { label: "3+", color: Qt.rgba(kbRoot.cWarning.r, kbRoot.cWarning.g, kbRoot.cWarning.b, 0.45), border: kbRoot.cWarning }
                ]
                Row {
                    required property var modelData
                    spacing: 4
                    Rectangle {
                        width: 10; height: 10; radius: 3
                        anchors.verticalCenter: parent.verticalCenter
                        color: modelData.color
                        border.width: 1
                        border.color: modelData.border
                    }
                    Text {
                        text: modelData.label
                        font.family: kbRoot.fontFamily
                        font.pixelSize: 10
                        color: kbRoot.cSubText
                    }
                }
            }
        }

        // Heatmap Toggle Pill
        Rectangle {
            Layout.preferredHeight: 28
            Layout.preferredWidth: heatRow.implicitWidth + 18
            radius: 8
            color: kbRoot.heatmapMode
                ? Qt.rgba(kbRoot.cWarning.r, kbRoot.cWarning.g, kbRoot.cWarning.b, 0.22)
                : heatHover.hovered
                    ? Qt.rgba(kbRoot.cText.r, kbRoot.cText.g, kbRoot.cText.b, 0.08)
                    : kbRoot.cContainer
            border.width: 1
            border.color: kbRoot.heatmapMode
                ? kbRoot.cWarning
                : Qt.rgba(kbRoot.cBorder.r, kbRoot.cBorder.g, kbRoot.cBorder.b, 0.35)

            HoverHandler { id: heatHover }

            Row {
                id: heatRow
                anchors.centerIn: parent
                spacing: 5
                Text {
                    text: "󰈸"
                    font.family: "Material Design Icons"
                    font.pixelSize: 13
                    color: kbRoot.heatmapMode ? kbRoot.cWarning : kbRoot.cSubText
                }
                Text {
                    text: "Heatmap"
                    font.family: kbRoot.fontFamily
                    font.pixelSize: 11
                    font.weight: kbRoot.heatmapMode ? Font.DemiBold : Font.Normal
                    color: kbRoot.heatmapMode ? kbRoot.cWarning : kbRoot.cText
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: kbRoot.heatmapMode = !kbRoot.heatmapMode
            }
        }

        // Detected Keyboard Profile Pill (click to cycle form factor)
        Rectangle {
            Layout.preferredHeight: 28
            Layout.preferredWidth: hwRow.implicitWidth + 18
            radius: 8
            color: hwHover.hovered
                ? Qt.rgba(kbRoot.cText.r, kbRoot.cText.g, kbRoot.cText.b, 0.08)
                : kbRoot.cContainer
            border.width: 1
            border.color: Qt.rgba(kbRoot.cBorder.r, kbRoot.cBorder.g, kbRoot.cBorder.b, 0.35)

            HoverHandler { id: hwHover }

            Row {
                id: hwRow
                anchors.centerIn: parent
                spacing: 5
                Text {
                    text: "󰌌"
                    font.family: "Material Design Icons"
                    font.pixelSize: 13
                    color: kbRoot.cPrimary
                }
                Text {
                    text: kbRoot.profileDisplayName()
                    font.family: kbRoot.fontFamily
                    font.pixelSize: 11
                    color: kbRoot.cText
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: kbRoot.cycleProfile()
            }
        }

        // CZ / US Layout Pill
        Rectangle {
            Layout.preferredHeight: 28
            Layout.preferredWidth: layoutTxt.implicitWidth + 16
            radius: 8
            color: layoutHover.hovered
                ? Qt.rgba(kbRoot.cPrimary.r, kbRoot.cPrimary.g, kbRoot.cPrimary.b, 0.16)
                : kbRoot.cContainer
            border.width: 1
            border.color: Qt.rgba(kbRoot.cBorder.r, kbRoot.cBorder.g, kbRoot.cBorder.b, 0.35)

            HoverHandler { id: layoutHover }

            Text {
                id: layoutTxt
                anchors.centerIn: parent
                text: kbRoot.activeLayout.toUpperCase() + (kbRoot.activeLayout.toLowerCase().startsWith("cz") ? " ISO" : " ANSI")
                font.family: "JetBrains Mono, monospace"
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: kbRoot.cPrimary
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: kbRoot.toggleLayoutCode()
            }
        }
    }

    // =========================================================================
    // 2. VISUAL KEYBOARD CHASSIS
    // =========================================================================
    Rectangle {
        id: boardContainer
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 280
        radius: 16
        color: kbRoot.cDeck
        border.width: 1
        border.color: Qt.rgba(kbRoot.cBorder.r, kbRoot.cBorder.g, kbRoot.cBorder.b, 0.45)

        readonly property real padX: 12
        readonly property real padY: 10
        readonly property real u: Math.max(
            28,
            Math.min(
                (width - padX * 2) / kbRoot.layoutData.totalWidth,
                (height - padY * 2) / kbRoot.layoutData.totalHeight
            )
        )
        readonly property real gap: Math.max(3, Math.round(u * 0.075))
        readonly property real boardW: kbRoot.layoutData.totalWidth * u
        readonly property real boardH: kbRoot.layoutData.totalHeight * u

        Item {
            id: keyboardCanvas
            width: boardContainer.boardW
            height: boardContainer.boardH
            anchors.centerIn: parent

            Repeater {
                model: kbRoot.layoutData.keys

                Item {
                    id: keyWrap
                    required property var modelData

                    readonly property real u: boardContainer.u
                    readonly property real gap: boardContainer.gap
                    readonly property bool isMod: modelData.mod.length > 0
                    readonly property bool isModActive: isMod && !kbRoot.showAllLayers && kbRoot.activeSubmap === "" && kbRoot.effectiveMods.indexOf(modelData.mod) !== -1
                    readonly property var allMatches: kbRoot.allBindsForKeySpec(modelData)
                    readonly property var layerMatches: kbRoot.layerBindsForKeySpec(modelData)
                    readonly property int totalCount: allMatches.length
                    readonly property int layerCount: layerMatches.length
                    readonly property bool isSelected: kbRoot.selectedKeyId === modelData.id
                    readonly property bool isHovered: keyMouse.containsMouse

                    // Decide visual state for current mode
                    readonly property bool hasActiveBind: kbRoot.heatmapMode ? totalCount > 0 : layerCount > 0
                    readonly property bool hasOtherBind: !kbRoot.heatmapMode && layerCount === 0 && totalCount > 0 && !kbRoot.isSearching
                    readonly property string capShortLabel: {
                        if (isMod) return ""
                        if (kbRoot.heatmapMode) {
                            return totalCount > 0 ? allMatches[0].shortLabel : ""
                        }
                        if (layerCount > 0) return layerMatches[0].shortLabel
                        return ""
                    }

                    readonly property color fillCol: {
                        if (isModActive) {
                            return kbRoot.isLiveActive
                                ? Qt.rgba(kbRoot.cSuccess.r, kbRoot.cSuccess.g, kbRoot.cSuccess.b, 0.28)
                                : kbRoot.cPrimaryContainer
                        }
                        if (kbRoot.heatmapMode && !isMod) {
                            if (totalCount >= 3) return Qt.rgba(kbRoot.cWarning.r, kbRoot.cWarning.g, kbRoot.cWarning.b, isHovered ? 0.36 : 0.24)
                            if (totalCount === 2) return isHovered ? Qt.lighter(kbRoot.cPrimaryContainer, 1.15) : kbRoot.cPrimaryContainer
                            if (totalCount === 1) return Qt.rgba(kbRoot.cPrimary.r, kbRoot.cPrimary.g, kbRoot.cPrimary.b, isHovered ? 0.24 : 0.14)
                            return isHovered ? kbRoot.cContainerHigh : kbRoot.cContainer
                        }
                        if (layerCount > 0) {
                            return isHovered
                                ? Qt.rgba(kbRoot.cPrimary.r, kbRoot.cPrimary.g, kbRoot.cPrimary.b, 0.30)
                                : kbRoot.cPrimaryContainer
                        }
                        if (isHovered) {
                            return kbRoot.cContainerHigh
                        }
                        return kbRoot.cContainer
                    }

                    readonly property color strokeCol: {
                        if (isSelected) return kbRoot.cText
                        if (isModActive) return kbRoot.isLiveActive ? kbRoot.cSuccess : kbRoot.cPrimary
                        if (kbRoot.heatmapMode && totalCount >= 3) return kbRoot.cWarning
                        if (hasActiveBind) return isHovered ? kbRoot.cPrimary : Qt.rgba(kbRoot.cPrimary.r, kbRoot.cPrimary.g, kbRoot.cPrimary.b, 0.72)
                        if (isHovered) return Qt.rgba(kbRoot.cText.r, kbRoot.cText.g, kbRoot.cText.b, 0.45)
                        return Qt.rgba(kbRoot.cBorder.r, kbRoot.cBorder.g, kbRoot.cBorder.b, 0.45)
                    }

                    readonly property real keyOpacity: {
                        if (isSelected || isHovered || isModActive) return 1.0
                        if (kbRoot.isSearching) return layerCount > 0 ? 1.0 : 0.34
                        if (kbRoot.heatmapMode) return totalCount > 0 ? 1.0 : 0.62
                        if (layerCount > 0) return 1.0
                        if (isMod) return 0.88
                        return hasOtherBind ? 0.82 : 0.64
                    }

                    x: Math.round(modelData.x * u)
                    y: Math.round(modelData.y * u)
                    width: Math.round(modelData.w * u) - gap
                    height: Math.round(modelData.h * u) - gap
                    z: modelData.isoEnter ? 1 : (isHovered || isSelected ? 4 : 2)
                    opacity: keyOpacity

                    Behavior on opacity { NumberAnimation { duration: 130 } }

                    // Standard rectangular tactile keycap
                    Rectangle {
                        visible: !keyWrap.modelData.isoEnter
                        anchors.fill: parent
                        radius: Math.max(5, Math.round(keyWrap.u * 0.14))
                        color: keyWrap.fillCol
                        border.width: keyWrap.isSelected ? 2 : 1
                        border.color: keyWrap.strokeCol

                        Behavior on color { ColorAnimation { duration: 110 } }
                        Behavior on border.color { ColorAnimation { duration: 110 } }

                        // Subtle tactile bottom bevel lip
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.leftMargin: 2
                            anchors.rightMargin: 2
                            anchors.bottomMargin: 1
                            height: 2
                            radius: 1
                            color: kbRoot.isLight ? Qt.rgba(0, 0, 0, 0.12) : Qt.rgba(0, 0, 0, 0.38)
                        }
                    }

                    // Authentic L-shaped ISO Enter keycap
                    Canvas {
                        id: isoCanvas
                        visible: keyWrap.modelData.isoEnter
                        anchors.fill: parent

                        property color cFill: keyWrap.fillCol
                        property color cStroke: keyWrap.strokeCol
                        property bool sel: keyWrap.isSelected
                        onCFillChanged: requestPaint()
                        onCStrokeChanged: requestPaint()
                        onSelChanged: requestPaint()
                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()

                        onPaint: {
                            const ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            const r = Math.max(5, Math.round(keyWrap.u * 0.14))
                            const w = width - 1
                            const h = height - 1
                            const notchX = Math.round(0.25 * keyWrap.u) + 1
                            const notchY = Math.round(1.0 * keyWrap.u) - keyWrap.gap + 2

                            ctx.beginPath()
                            ctx.moveTo(r + 1, 1)
                            ctx.lineTo(w - r, 1)
                            ctx.quadraticCurveTo(w, 1, w, r + 1)
                            ctx.lineTo(w, h - r)
                            ctx.quadraticCurveTo(w, h, w - r, h)
                            ctx.lineTo(notchX + r, h)
                            ctx.quadraticCurveTo(notchX, h, notchX, h - r)
                            ctx.lineTo(notchX, notchY + 2)
                            ctx.lineTo(r + 1, notchY + 2)
                            ctx.quadraticCurveTo(1, notchY + 2, 1, notchY + 2 - r)
                            ctx.lineTo(1, r + 1)
                            ctx.quadraticCurveTo(1, 1, r + 1, 1)
                            ctx.closePath()

                            ctx.fillStyle = cFill.toString()
                            ctx.fill()
                            ctx.lineWidth = sel ? 2 : 1
                            ctx.strokeStyle = cStroke.toString()
                            ctx.stroke()
                        }
                    }

                    // Top-left primary legend
                    Text {
                        id: mainLegend
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: countBadge.visible ? countBadge.left : parent.right
                        anchors.topMargin: keyWrap.modelData.compact ? 4 : 5
                        anchors.leftMargin: keyWrap.modelData.isoEnter ? Math.round(keyWrap.u * 0.30) : 6
                        anchors.rightMargin: countBadge.visible ? 2 : 4
                        text: keyWrap.modelData.label
                        elide: Text.ElideRight
                        font.family: (keyWrap.modelData.label.length === 1 && keyWrap.modelData.label.charCodeAt(0) > 9000)
                            ? "Material Design Icons"
                            : "JetBrains Mono, monospace"
                        font.pixelSize: keyWrap.modelData.compact
                            ? Math.max(9, Math.round(keyWrap.u * 0.21))
                            : (keyWrap.modelData.label.length > 3
                                ? Math.max(9, Math.round(keyWrap.u * 0.21))
                                : Math.max(10, Math.round(keyWrap.u * 0.25)))
                        font.weight: (keyWrap.hasActiveBind || keyWrap.isModActive) ? Font.Bold : Font.Medium
                        color: (keyWrap.hasActiveBind || keyWrap.isModActive) ? kbRoot.cOnPrimaryContainer : kbRoot.cSubText
                    }

                    // Top-right subtle secondary legend (CZ shift char / Fn icon) OR count badge
                    Text {
                        visible: keyWrap.modelData.sub.length > 0 && !countBadge.visible && keyWrap.width >= 34
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: 4
                        anchors.rightMargin: 5
                        text: keyWrap.modelData.sub
                        font.family: (keyWrap.modelData.sub.length === 1 && keyWrap.modelData.sub.charCodeAt(0) > 9000)
                            ? "Material Design Icons"
                            : "JetBrains Mono, monospace"
                        font.pixelSize: Math.max(8, Math.round(keyWrap.u * 0.17))
                        color: kbRoot.cSubText
                        opacity: 0.65
                    }

                    // Bind count badge (Heatmap mode or multi-bind key in layer mode)
                    Rectangle {
                        id: countBadge
                        visible: !keyWrap.isMod && (
                            (kbRoot.heatmapMode && keyWrap.totalCount > 0)
                            || (!kbRoot.heatmapMode && keyWrap.layerCount > 1)
                        )
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: 3
                        anchors.rightMargin: 3
                        width: Math.max(14, badgeTxt.implicitWidth + 6)
                        height: 14
                        radius: 4
                        color: (kbRoot.heatmapMode && keyWrap.totalCount >= 3)
                            ? kbRoot.cWarning
                            : kbRoot.cPrimary

                        Text {
                            id: badgeTxt
                            anchors.centerIn: parent
                            text: (kbRoot.heatmapMode ? keyWrap.totalCount : keyWrap.layerCount).toString()
                            font.family: "JetBrains Mono, monospace"
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            color: (kbRoot.heatmapMode && keyWrap.totalCount >= 3) ? kbRoot.cOnWarning : kbRoot.cOnPrimary
                        }
                    }

                    // Quiet dot when key has binds on OTHER modifiers (not current layer)
                    Rectangle {
                        visible: keyWrap.hasOtherBind && !keyWrap.isMod && !countBadge.visible
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        anchors.bottomMargin: 5
                        anchors.rightMargin: 5
                        width: 4
                        height: 4
                        radius: 2
                        color: kbRoot.cPrimary
                        opacity: 0.7
                    }

                    // Bottom short action label directly on bound keycap
                    Text {
                        visible: keyWrap.capShortLabel.length > 0 && !keyWrap.modelData.compact
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: keyWrap.modelData.isoEnter ? Math.round(keyWrap.u * 0.28) : 4
                        anchors.rightMargin: 4
                        anchors.bottomMargin: 5
                        text: keyWrap.capShortLabel
                        font.family: kbRoot.fontFamily
                        font.pixelSize: Math.max(8, Math.round(keyWrap.u * 0.17))
                        font.weight: Font.DemiBold
                        color: (kbRoot.heatmapMode && keyWrap.totalCount >= 3) ? kbRoot.cWarning : kbRoot.cPrimary
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    MouseArea {
                        id: keyMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onEntered: kbRoot.hoveredKeyId = keyWrap.modelData.id
                        onExited: {
                            if (kbRoot.hoveredKeyId === keyWrap.modelData.id) {
                                kbRoot.hoveredKeyId = ""
                            }
                        }
                        onClicked: {
                            if (keyWrap.isMod) {
                                kbRoot.toggleModifierKey(keyWrap.modelData.mod)
                            }
                            if (kbRoot.selectedKeyId === keyWrap.modelData.id) {
                                kbRoot.selectedKeyId = ""
                            } else {
                                kbRoot.selectedKeyId = keyWrap.modelData.id
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // 3. BOTTOM ROW: Mouse Controls Strip + Key Inspector Panel
    // =========================================================================
    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 118
        spacing: 10

        // Compact Mouse Controls Card
        Rectangle {
            Layout.preferredWidth: 210
            Layout.fillHeight: true
            radius: 14
            color: kbRoot.cContainer
            border.width: 1
            border.color: Qt.rgba(kbRoot.cBorder.r, kbRoot.cBorder.g, kbRoot.cBorder.b, 0.30)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Text {
                        text: "󰍽"
                        font.family: "Material Design Icons"
                        font.pixelSize: 13
                        color: kbRoot.cPrimary
                    }
                    Text {
                        text: "Myš"
                        font.family: kbRoot.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: kbRoot.cText
                    }
                    Item { Layout.fillWidth: true }
                }

                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 2
                    rowSpacing: 6
                    columnSpacing: 6

                    Repeater {
                        model: Layouts.MOUSE_CONTROLS

                        Rectangle {
                            id: mouseKey
                            required property var modelData
                            readonly property var allM: kbRoot.allBindsForKeySpec(modelData)
                            readonly property var layerM: kbRoot.layerBindsForKeySpec(modelData)
                            readonly property bool active: kbRoot.heatmapMode ? allM.length > 0 : layerM.length > 0
                            readonly property bool sel: kbRoot.selectedKeyId === modelData.id

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 8
                            color: active
                                ? Qt.rgba(kbRoot.cPrimary.r, kbRoot.cPrimary.g, kbRoot.cPrimary.b, mMouse.containsMouse ? 0.32 : 0.18)
                                : mMouse.containsMouse
                                    ? Qt.rgba(kbRoot.cText.r, kbRoot.cText.g, kbRoot.cText.b, 0.08)
                                    : kbRoot.cContainerLow
                            border.width: sel ? 2 : 1
                            border.color: sel
                                ? kbRoot.cText
                                : active
                                    ? Qt.rgba(kbRoot.cPrimary.r, kbRoot.cPrimary.g, kbRoot.cPrimary.b, 0.65)
                                    : Qt.rgba(kbRoot.cBorder.r, kbRoot.cBorder.g, kbRoot.cBorder.b, 0.30)
                            opacity: active || mMouse.containsMouse || sel ? 1.0 : 0.45

                            Column {
                                anchors.centerIn: parent
                                spacing: 1
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: mouseKey.modelData.label
                                    font.family: "JetBrains Mono, monospace"
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                    color: mouseKey.active ? kbRoot.cText : kbRoot.cSubText
                                }
                                Text {
                                    visible: mouseKey.layerM.length > 0 || (kbRoot.heatmapMode && mouseKey.allM.length > 0)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: mouseKey.layerM.length > 0
                                        ? mouseKey.layerM[0].shortLabel
                                        : (mouseKey.allM.length > 0 ? mouseKey.allM[0].shortLabel : "")
                                    font.family: kbRoot.fontFamily
                                    font.pixelSize: 9
                                    color: kbRoot.cPrimary
                                }
                            }

                            MouseArea {
                                id: mMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: kbRoot.hoveredKeyId = mouseKey.modelData.id
                                onExited: {
                                    if (kbRoot.hoveredKeyId === mouseKey.modelData.id) kbRoot.hoveredKeyId = ""
                                }
                                onClicked: {
                                    kbRoot.selectedKeyId = (kbRoot.selectedKeyId === mouseKey.modelData.id)
                                        ? ""
                                        : mouseKey.modelData.id
                                }
                            }
                        }
                    }
                }
            }
        }

        // Bottom Key Inspector Card
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 14
            color: kbRoot.cContainer
            border.width: 1
            border.color: kbRoot.inspectedSpec
                ? Qt.rgba(kbRoot.cPrimary.r, kbRoot.cPrimary.g, kbRoot.cPrimary.b, 0.40)
                : Qt.rgba(kbRoot.cBorder.r, kbRoot.cBorder.g, kbRoot.cBorder.b, 0.30)

            // Active key inspection state
            RowLayout {
                visible: kbRoot.inspectedSpec !== null
                anchors.fill: parent
                anchors.margins: 12
                spacing: 14

                // Left keycap preview tile
                ColumnLayout {
                    Layout.preferredWidth: 112
                    Layout.fillHeight: true
                    spacing: 4

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: Math.max(54, previewCapText.implicitWidth + 22)
                        height: 46
                        radius: 10
                        color: kbRoot.inspectedAllBinds.length > 0
                            ? Qt.rgba(kbRoot.cPrimary.r, kbRoot.cPrimary.g, kbRoot.cPrimary.b, 0.22)
                            : kbRoot.cContainerLow
                        border.width: 1
                        border.color: kbRoot.inspectedAllBinds.length > 0
                            ? kbRoot.cPrimary
                            : kbRoot.cBorder

                        Text {
                            id: previewCapText
                            anchors.centerIn: parent
                            text: kbRoot.inspectedSpec ? kbRoot.inspectedSpec.label : ""
                            font.family: (text.length === 1 && text.charCodeAt(0) > 9000)
                                ? "Material Design Icons"
                                : "JetBrains Mono, monospace"
                            font.pixelSize: text.length > 4 ? 13 : 17
                            font.weight: Font.Bold
                            color: kbRoot.cText
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: kbRoot.inspectedAllBinds.length > 0
                            ? `${kbRoot.inspectedAllBinds.length} ${kbRoot.inspectedAllBinds.length === 1 ? "zkratka" : (kbRoot.inspectedAllBinds.length < 5 ? "zkratky" : "zkratek")}`
                            : "Volná klávesa"
                        font.family: kbRoot.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: kbRoot.inspectedAllBinds.length > 0 ? kbRoot.cPrimary : kbRoot.cSuccess
                    }

                    Text {
                        visible: kbRoot.selectedKeyId.length > 0 && kbRoot.hoveredKeyId.length === 0
                        Layout.alignment: Qt.AlignHCenter
                        text: "Připnuto · klik odejme"
                        font.family: kbRoot.fontFamily
                        font.pixelSize: 9
                        color: kbRoot.cSubText
                    }
                }

                // Divider
                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    color: kbRoot.cBorder
                    opacity: 0.35
                }

                // Right binds list for inspected key
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // Empty / free key message
                    ColumnLayout {
                        visible: kbRoot.inspectedAllBinds.length === 0
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Text {
                            text: kbRoot.inspectedSpec
                                ? `Klávesa „${kbRoot.inspectedSpec.label}“ nemá žádný přiřazený keybind`
                                : ""
                            font.family: kbRoot.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: kbRoot.cText
                        }

                        Text {
                            text: `Volná pro novou zkratku (např. ${kbRoot.effectiveMods.length > 0 ? kbRoot.effectiveMods.join(" + ") + " + " : "Super + "}${kbRoot.inspectedSpec ? kbRoot.inspectedSpec.id : ""})`
                            font.family: "JetBrains Mono, monospace"
                            font.pixelSize: 11
                            color: kbRoot.cSubText
                        }
                    }

                    // Scrollable binds list on this key
                    Flickable {
                        visible: kbRoot.inspectedAllBinds.length > 0
                        anchors.fill: parent
                        clip: true
                        contentWidth: width
                        contentHeight: inspCol.height
                        boundsBehavior: Flickable.StopAtBounds

                        QQC.ScrollBar.vertical: QQC.ScrollBar { policy: QQC.ScrollBar.AsNeeded }

                        Column {
                            id: inspCol
                            width: parent.width - 8
                            spacing: 5

                            Repeater {
                                model: kbRoot.inspectedAllBinds

                                Rectangle {
                                    id: inspRow
                                    required property var modelData
                                    readonly property bool inLayer: kbRoot.bindMatchesActiveLayer(modelData)

                                    width: inspCol.width
                                    height: 30
                                    radius: 8
                                    color: inLayer
                                        ? Qt.rgba(kbRoot.cPrimary.r, kbRoot.cPrimary.g, kbRoot.cPrimary.b, 0.14)
                                        : Qt.rgba(kbRoot.cText.r, kbRoot.cText.g, kbRoot.cText.b, 0.03)
                                    border.width: 1
                                    border.color: inLayer
                                        ? Qt.rgba(kbRoot.cPrimary.r, kbRoot.cPrimary.g, kbRoot.cPrimary.b, 0.40)
                                        : Qt.rgba(kbRoot.cBorder.r, kbRoot.cBorder.g, kbRoot.cBorder.b, 0.20)
                                    opacity: inLayer || kbRoot.heatmapMode || kbRoot.showAllLayers ? 1.0 : 0.58

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 10

                                        Rectangle {
                                            Layout.preferredHeight: 20
                                            Layout.preferredWidth: inspComboTxt.implicitWidth + 12
                                            radius: 5
                                            color: Qt.rgba(kbRoot.cPrimary.r, kbRoot.cPrimary.g, kbRoot.cPrimary.b, 0.20)

                                            Text {
                                                id: inspComboTxt
                                                anchors.centerIn: parent
                                                text: inspRow.modelData.key
                                                font.family: "JetBrains Mono, monospace"
                                                font.pixelSize: 10
                                                font.weight: Font.DemiBold
                                                color: kbRoot.cPrimary
                                            }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: inspRow.modelData.action
                                            font.family: kbRoot.fontFamily
                                            font.pixelSize: 12
                                            color: kbRoot.cText
                                            elide: Text.ElideRight
                                        }

                                        Rectangle {
                                            Layout.preferredHeight: 18
                                            Layout.preferredWidth: inspCatTxt.implicitWidth + 10
                                            radius: 5
                                            color: Qt.rgba(kbRoot.cText.r, kbRoot.cText.g, kbRoot.cText.b, 0.07)

                                            Text {
                                                id: inspCatTxt
                                                anchors.centerIn: parent
                                                text: inspRow.modelData.cat
                                                font.family: kbRoot.fontFamily
                                                font.pixelSize: 9
                                                color: kbRoot.cSubText
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Idle state when no key is hovered/selected
            RowLayout {
                visible: kbRoot.inspectedSpec === null
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                Rectangle {
                    width: 44; height: 44; radius: 12
                    color: Qt.rgba(kbRoot.cPrimary.r, kbRoot.cPrimary.g, kbRoot.cPrimary.b, 0.14)
                    border.width: 1
                    border.color: Qt.rgba(kbRoot.cPrimary.r, kbRoot.cPrimary.g, kbRoot.cPrimary.b, 0.30)

                    Text {
                        anchors.centerIn: parent
                        text: "󰌌"
                        font.family: "Material Design Icons"
                        font.pixelSize: 22
                        color: kbRoot.cPrimary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Text {
                        text: `Vrstva: ${kbRoot.activeLayerTitle()} · ${kbRoot.layerStats.bound} obsazených kláves · ${kbRoot.layerStats.freeAlpha} volných písmen`
                        font.family: kbRoot.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: kbRoot.cText
                    }

                    Text {
                        text: "Najeď myší nebo klikni na libovolnou klávesu pro seznam jejích zkratek. Klikem na Super/Shift/Alt/Ctrl (nebo jejich držením) přepínáš vrstvy."
                        font.family: kbRoot.fontFamily
                        font.pixelSize: 11
                        color: kbRoot.cSubText
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}

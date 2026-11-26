import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10 as QQC
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../../config" as QsConfig
import "../../services" as QsServices
import "../../components"
import "../../components/effects"

PanelWindow {
    id: root

    property bool shouldShow: false
    property string selectedCategory: "Applications"
    property string query: ""
    property string viewMode: "list" // "list" | "keyboard"

    // Live physically held modifiers (updated via Keys.onPressed / onReleased)
    property bool liveSuper: false
    property bool liveCtrl: false
    property bool liveAlt: false
    property bool liveShift: false
    readonly property var liveMods: {
        const mods = []
        if (liveSuper) mods.push("Super")
        if (liveCtrl) mods.push("Ctrl")
        if (liveAlt) mods.push("Alt")
        if (liveShift) mods.push("Shift")
        return mods
    }

    function updateLiveModifiers(event, pressed) {
        if (event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R || event.key === Qt.Key_Meta) {
            liveSuper = pressed
        } else if (event.key === Qt.Key_Control) {
            liveCtrl = pressed
        } else if (event.key === Qt.Key_Alt || event.key === Qt.Key_AltGr) {
            liveAlt = pressed
        } else if (event.key === Qt.Key_Shift) {
            liveShift = pressed
        }
        if (pressed) {
            if (event.modifiers & Qt.MetaModifier) liveSuper = true
            if (event.modifiers & Qt.ControlModifier) liveCtrl = true
            if (event.modifiers & Qt.AltModifier) liveAlt = true
            if (event.modifiers & Qt.ShiftModifier) liveShift = true
        }
    }

    function resetLiveModifiers() {
        liveSuper = false
        liveCtrl = false
        liveAlt = false
        liveShift = false
    }

    readonly property var config: QsConfig.Config
    readonly property var pywal: QsServices.Pywal
    readonly property color cSurface: pywal.surface
    readonly property color cDeck: pywal.surfaceContainerLowest
    readonly property color cContainer: pywal.surfaceContainer
    readonly property color cContainerLow: pywal.surfaceContainerLow
    readonly property color cContainerHigh: pywal.surfaceContainerHigh
    readonly property color cPrimary: pywal.primary
    readonly property color cOnPrimary: pywal.m3onPrimary
    readonly property color cPrimaryContainer: pywal.primaryContainer
    readonly property color cOnPrimaryContainer: pywal.m3onPrimaryContainer
    readonly property color cText: pywal.m3onSurface
    readonly property color cSubText: pywal.m3onSurfaceMuted
    readonly property color cBorder: pywal.outlineVariant

    // Dynamically extracted keybinds, categories, and detected keyboard hardware
    property var allBinds: []
    property var categoryList: []
    property var keyboardInfo: ({})

    readonly property string extractorPath: Qt.resolvedUrl("../../services/extract_keybinds.py").toString().replace(/^file:\/\//, "")

    Process {
        id: extractProc
        command: ["python3", root.extractorPath, root.config.keybindhelp.hyprConfigDir]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim().length === 0) return
                try {
                    const parsed = JSON.parse(text)
                    if (parsed.keyboard && typeof parsed.keyboard === "object") {
                        root.keyboardInfo = parsed.keyboard
                    }
                    if (Array.isArray(parsed.binds)) {
                        root.allBinds = parsed.binds
                    }
                    if (Array.isArray(parsed.categories)) {
                        root.categoryList = parsed.categories
                        const hasSelected = parsed.categories.some(c => c.name === root.selectedCategory)
                        if (!hasSelected && parsed.categories.length > 0) {
                            root.selectedCategory = parsed.categories[0].name
                        }
                    }
                } catch (e) {
                    QsServices.Logger.warn("KeybindHelp", `Failed to parse extracted keybinds: ${(e && e.message) ? e.message : e}`)
                }
            }
        }
    }

    function refreshKeybinds() {
        if (!extractProc.running) {
            extractProc.command = ["python3", root.extractorPath, root.config.keybindhelp.hyprConfigDir]
            extractProc.running = true
        }
    }

    Component.onCompleted: refreshKeybinds()

    // Active keybinds list: either filtered by search or the selected category
    readonly property var currentBinds: {
        const q = query.trim().toLowerCase()
        if (q.length > 0) {
            return allBinds.filter(item => {
                return item.key.toLowerCase().includes(q)
                    || item.action.toLowerCase().includes(q)
                    || item.cat.toLowerCase().includes(q)
            })
        }
        return allBinds.filter(item => item.cat === selectedCategory)
    }

    function countForCategory(catName) {
        return allBinds.filter(item => item.cat === catName).length
    }

    function nextCategory() {
        if (categoryList.length === 0) return
        const idx = categoryList.findIndex(c => c.name === selectedCategory)
        const nextIdx = (idx + 1) % categoryList.length
        selectedCategory = categoryList[nextIdx].name
        bindFlickable.contentY = 0
    }

    function prevCategory() {
        if (categoryList.length === 0) return
        const idx = categoryList.findIndex(c => c.name === selectedCategory)
        const prevIdx = (idx - 1 + categoryList.length) % categoryList.length
        selectedCategory = categoryList[prevIdx].name
        bindFlickable.contentY = 0
    }

    function currentCategoryIcon() {
        const cat = categoryList.find(c => c.name === selectedCategory)
        return cat ? cat.icon : "󰘴"
    }

    onShouldShowChanged: {
        resetLiveModifiers()
        if (shouldShow) {
            refreshKeybinds()
            query = ""
            if (bindFlickable) bindFlickable.contentY = 0
            Qt.callLater(() => {
                mainPanel.forceActiveFocus()
                if (viewMode === "list") searchInput.forceActiveFocus()
            })
        }
    }

    IpcHandler {
        target: "keybindhelp"

        function toggle() {
            root.shouldShow = !root.shouldShow
        }

        function open() {
            root.shouldShow = true
        }

        function toggleKeyboard() {
            if (root.shouldShow && root.viewMode === "keyboard") {
                root.shouldShow = false
            } else {
                root.viewMode = "keyboard"
                root.shouldShow = true
            }
        }

        function setView(mode: string) {
            if (mode === "list" || mode === "keyboard") {
                root.viewMode = mode
            }
        }

        function setTheme(name: string) {
            root.pywal.setTheme(name)
        }

        function cycleTheme() {
            root.pywal.cycleTheme()
        }

        function close() {
            root.shouldShow = false
        }

        function refresh() {
            root.refreshKeybinds()
        }
    }

    screen: Quickshell.screens[0]
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    color: "transparent"
    visible: shouldShow || overlay.opacity > 0

    WlrLayershell.namespace: "quickshell-keybindhelp"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Backdrop click to close
    MouseArea {
        anchors.fill: parent
        enabled: root.shouldShow
        onClicked: root.shouldShow = false
    }

    // Overlay dim
    Rectangle {
        id: overlay
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.65)
        opacity: root.shouldShow ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation {
                duration: root.shouldShow ? 200 : 200
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.shouldShow ? Material3Anim.expressiveDefaultEffects : Material3Anim.emphasizedAccel
            }
        }
    }

    // Main Card FocusScope
    FocusScope {
        id: mainPanel
        anchors.centerIn: parent
        width: root.viewMode === "keyboard"
            ? Math.min(1260, parent.width - 48)
            : Math.min(940, parent.width - 60)
        height: root.viewMode === "keyboard"
            ? Math.min(720, parent.height - 48)
            : Math.min(640, parent.height - 60)
        focus: root.shouldShow

        Behavior on width {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
        Behavior on height {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        property real revealY: root.shouldShow ? 0 : 20
        property real panelOpacity: root.shouldShow ? 1.0 : 0.0
        property real panelScale: root.shouldShow ? 1.0 : 0.96

        opacity: panelOpacity
        scale: panelScale
        transform: Translate { y: mainPanel.revealY }

        Behavior on revealY {
            NumberAnimation {
                duration: root.shouldShow ? 500 : 240
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.shouldShow ? Material3Anim.expressiveDefaultSpatial : Material3Anim.emphasizedAccel
            }
        }
        Behavior on panelOpacity {
            NumberAnimation {
                duration: root.shouldShow ? 200 : 200
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.shouldShow ? Material3Anim.expressiveDefaultEffects : Material3Anim.emphasizedAccel
            }
        }
        Behavior on panelScale {
            NumberAnimation {
                duration: root.shouldShow ? 500 : 240
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.shouldShow ? Material3Anim.expressiveDefaultSpatial : Material3Anim.emphasizedAccel
            }
        }

        // Keyboard navigation + live modifier tracking on mainPanel
        Keys.onPressed: event => {
            root.updateLiveModifiers(event, true)
            if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_Tab) {
                root.viewMode = (root.viewMode === "list") ? "keyboard" : "list"
                event.accepted = true
                return
            }
            if (event.key === Qt.Key_Escape) {
                if (root.viewMode === "keyboard" && keyboardMap.selectedKeyId.length > 0) {
                    keyboardMap.selectedKeyId = ""
                } else {
                    root.shouldShow = false
                }
                event.accepted = true
            } else if (root.viewMode === "list") {
                if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                    root.nextCategory()
                    event.accepted = true
                } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                    root.prevCategory()
                    event.accepted = true
                }
            }
        }
        Keys.onReleased: event => {
            root.updateLiveModifiers(event, false)
        }

        // Eat backdrop clicks inside the card
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        AuroraSurface {
            anchors.fill: parent
            radius: 24
            color: root.cSurface
            strokeColor: root.cBorder
            accentColor: root.cPrimary
            elevation: 6
            highlighted: false

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                // Top Header Row
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    spacing: 12

                    Rectangle {
                        width: 38; height: 38
                        radius: 12
                        color: Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.15)
                        border.width: 1
                        border.color: Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.30)

                        Text {
                            anchors.centerIn: parent
                            text: "󰘴"
                            font.family: "Material Design Icons"
                            font.pixelSize: 22
                            color: root.cPrimary
                        }
                    }

                    ColumnLayout {
                        spacing: 1

                        Text {
                            text: "Keybind Reference"
                            font.family: root.config.appearance.fontFamily
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                            color: root.cText
                        }

                        Text {
                            text: root.viewMode === "keyboard"
                                ? "Vizuální mapa reálných zkratek • Podrž modifikátor nebo klikni na klávesu"
                                : "Use ↑↓ arrows or click a category to view shortcuts • Esc to close"
                            font.family: root.config.appearance.fontFamily
                            font.pixelSize: 11
                            color: root.cSubText
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Theme Picker Pill (Auto Caelestia / Standalone Presets)
                    Rectangle {
                        Layout.preferredHeight: 34
                        Layout.preferredWidth: themePillRow.implicitWidth + 18
                        radius: 10
                        color: themePillHover.hovered ? root.cContainerHigh : root.cContainer
                        border.width: 1
                        border.color: themePillHover.hovered
                            ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.50)
                            : Qt.rgba(root.cBorder.r, root.cBorder.g, root.cBorder.b, 0.45)

                        Behavior on color { ColorAnimation { duration: 120 } }

                        HoverHandler { id: themePillHover }

                        Row {
                            id: themePillRow
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "󰏘"
                                font.family: "Material Design Icons"
                                font.pixelSize: 14
                                color: root.cPrimary
                            }

                            Text {
                                text: root.pywal.activeThemeLabel
                                font.family: root.config.appearance.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: root.cText
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton) {
                                    root.pywal.setTheme("auto")
                                } else {
                                    root.pywal.cycleTheme()
                                }
                            }
                        }
                    }

                    // Segmented View Mode Switcher (Seznam | Klávesnice)
                    Rectangle {
                        Layout.preferredHeight: 34
                        Layout.preferredWidth: viewSwitchRow.implicitWidth + 8
                        radius: 10
                        color: root.cContainer
                        border.width: 1
                        border.color: Qt.rgba(root.cBorder.r, root.cBorder.g, root.cBorder.b, 0.35)

                        Row {
                            id: viewSwitchRow
                            anchors.centerIn: parent
                            spacing: 4

                            Repeater {
                                model: [
                                    { id: "list", label: "Seznam", icon: "󰕰" },
                                    { id: "keyboard", label: "Klávesnice", icon: "󰌌" }
                                ]

                                Rectangle {
                                    id: viewTab
                                    required property var modelData
                                    readonly property bool active: root.viewMode === modelData.id

                                    height: 26
                                    width: tabContent.implicitWidth + 18
                                    radius: 7
                                    color: active
                                        ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.22)
                                        : tabHover.hovered
                                            ? Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.06)
                                            : "transparent"
                                    border.width: active ? 1 : 0
                                    border.color: Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.45)

                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    HoverHandler { id: tabHover }

                                    Row {
                                        id: tabContent
                                        anchors.centerIn: parent
                                        spacing: 6

                                        Text {
                                            text: viewTab.modelData.icon
                                            font.family: "Material Design Icons"
                                            font.pixelSize: 14
                                            color: viewTab.active ? root.cPrimary : root.cSubText
                                        }

                                        Text {
                                            text: viewTab.modelData.label
                                            font.family: root.config.appearance.fontFamily
                                            font.pixelSize: 12
                                            font.weight: viewTab.active ? Font.DemiBold : Font.Normal
                                            color: viewTab.active ? root.cText : root.cSubText
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.viewMode = viewTab.modelData.id
                                            if (root.viewMode === "keyboard") {
                                                mainPanel.forceActiveFocus()
                                            } else {
                                                searchInput.forceActiveFocus()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Close Button
                    Rectangle {
                        width: 34; height: 34
                        radius: 10
                        color: closeHover.containsMouse
                            ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.20)
                            : "transparent"
                        border.width: 1
                        border.color: closeHover.containsMouse ? root.cPrimary : "transparent"

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: "󰖭"
                            font.family: "Material Design Icons"
                            font.pixelSize: 18
                            color: closeHover.containsMouse ? root.cPrimary : root.cSubText
                        }

                        MouseArea {
                            id: closeHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.shouldShow = false
                        }
                    }
                }

                // Interactive Search Box
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    radius: 14
                    color: root.cContainer
                    border.width: searchInput.activeFocus ? 2 : 1
                    border.color: searchInput.activeFocus ? root.cPrimary : Qt.rgba(root.cBorder.r, root.cBorder.g, root.cBorder.b, 0.4)

                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 12
                        spacing: 10

                        Text {
                            text: "󰍉"
                            font.family: "Material Design Icons"
                            font.pixelSize: 18
                            color: searchInput.activeFocus ? root.cPrimary : root.cSubText
                        }

                        QQC.TextField {
                            id: searchInput
                            Layout.fillWidth: true
                            color: root.cText
                            font.family: root.config.appearance.fontFamily
                            font.pixelSize: 14
                            placeholderText: "Type to search shortcuts... (e.g. terminal, float, ws, audio)"
                            placeholderTextColor: root.cSubText
                            background: Item {}
                            selectByMouse: true
                            focus: true

                            onTextChanged: {
                                root.query = text
                                if (bindFlickable) bindFlickable.contentY = 0
                            }

                            Keys.onPressed: event => {
                                root.updateLiveModifiers(event, true)
                                if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_Tab) {
                                    root.viewMode = (root.viewMode === "list") ? "keyboard" : "list"
                                    if (root.viewMode === "keyboard") mainPanel.forceActiveFocus()
                                    event.accepted = true
                                }
                            }
                            Keys.onReleased: event => {
                                root.updateLiveModifiers(event, false)
                            }
                            Keys.onDownPressed: event => {
                                if (root.viewMode === "list") {
                                    root.nextCategory()
                                    event.accepted = true
                                }
                            }
                            Keys.onUpPressed: event => {
                                if (root.viewMode === "list") {
                                    root.prevCategory()
                                    event.accepted = true
                                }
                            }
                            Keys.onTabPressed: event => {
                                if (root.viewMode === "list") {
                                    root.nextCategory()
                                    event.accepted = true
                                }
                            }
                            Keys.onBacktabPressed: event => {
                                if (root.viewMode === "list") {
                                    root.prevCategory()
                                    event.accepted = true
                                }
                            }
                            Keys.onEscapePressed: event => {
                                if (text.length > 0) {
                                    text = ""
                                } else {
                                    root.shouldShow = false
                                }
                                event.accepted = true
                            }
                        }

                        // Clear Button
                        Rectangle {
                            visible: root.query.length > 0
                            width: 22; height: 22
                            radius: 11
                            color: clearHover.containsMouse ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.25) : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "󰅖"
                                font.family: "Material Design Icons"
                                font.pixelSize: 14
                                color: root.cSubText
                            }

                            MouseArea {
                                id: clearHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    searchInput.text = ""
                                    searchInput.forceActiveFocus()
                                }
                            }
                        }

                        // Results counter badge
                        Rectangle {
                            Layout.preferredHeight: 24
                            Layout.preferredWidth: countText.implicitWidth + 14
                            radius: 6
                            color: Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.12)

                            Text {
                                id: countText
                                anchors.centerIn: parent
                                text: root.query.length > 0
                                    ? (root.currentBinds.length + " found")
                                    : (root.viewMode === "keyboard"
                                        ? (keyboardMap.layerStats.bound + " active · " + root.allBinds.length + " total")
                                        : (root.currentBinds.length + " shortcuts"))
                                font.family: root.config.appearance.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: root.cPrimary
                            }
                        }
                    }
                }

                // Main Body: List View (Categories + Keybinds)
                RowLayout {
                    visible: root.viewMode === "list"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 14

                    // Left Categories Column (Fixed 220px width)
                    ColumnLayout {
                        Layout.fillWidth: false
                        Layout.preferredWidth: 220
                        Layout.fillHeight: true
                        spacing: 4

                        Text {
                            text: "CATEGORIES"
                            font.family: root.config.appearance.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: root.cSubText
                            leftPadding: 8
                            bottomPadding: 4
                        }

                        Flickable {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            contentWidth: width
                            contentHeight: catCol.height
                            boundsBehavior: Flickable.StopAtBounds

                            Column {
                                id: catCol
                                width: parent.width
                                spacing: 3

                                Repeater {
                                    model: root.categoryList

                                    Rectangle {
                                        id: catBtn
                                        required property var modelData

                                        width: catCol.width
                                        height: 38
                                        radius: 10
                                        color: (root.query.length === 0 && root.selectedCategory === modelData.name)
                                            ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.20)
                                            : catItemHover.hovered
                                                ? Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.06)
                                                : "transparent"
                                        border.width: (root.query.length === 0 && root.selectedCategory === modelData.name) ? 1 : 0
                                        border.color: Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.40)

                                        Behavior on color { ColorAnimation { duration: 120 } }

                                        HoverHandler { id: catItemHover }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 10
                                            spacing: 10

                                            Text {
                                                text: catBtn.modelData.icon
                                                font.family: "Material Design Icons"
                                                font.pixelSize: 16
                                                color: (root.query.length === 0 && root.selectedCategory === catBtn.modelData.name)
                                                    ? root.cPrimary
                                                    : root.cSubText
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: catBtn.modelData.name
                                                font.family: root.config.appearance.fontFamily
                                                font.pixelSize: 12
                                                font.weight: (root.query.length === 0 && root.selectedCategory === catBtn.modelData.name) ? Font.DemiBold : Font.Normal
                                                color: (root.query.length === 0 && root.selectedCategory === catBtn.modelData.name) ? root.cText : root.cSubText
                                                elide: Text.ElideRight
                                            }

                                            Rectangle {
                                                Layout.preferredHeight: 18
                                                Layout.preferredWidth: catBadgeText.implicitWidth + 8
                                                radius: 5
                                                color: (root.query.length === 0 && root.selectedCategory === catBtn.modelData.name)
                                                    ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.25)
                                                    : Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.06)

                                                Text {
                                                    id: catBadgeText
                                                    anchors.centerIn: parent
                                                    text: root.countForCategory(catBtn.modelData.name).toString()
                                                    font.family: root.config.appearance.fontFamily
                                                    font.pixelSize: 10
                                                    font.weight: Font.Medium
                                                    color: (root.query.length === 0 && root.selectedCategory === catBtn.modelData.name) ? root.cPrimary : root.cSubText
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.query = ""
                                                searchInput.text = ""
                                                root.selectedCategory = catBtn.modelData.name
                                                if (bindFlickable) bindFlickable.contentY = 0
                                                searchInput.forceActiveFocus()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Vertical Separator
                    Rectangle {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        color: root.cBorder
                        opacity: 0.35
                    }

                    // Right Keybinds List (Spans remaining width)
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 8

                        // Section Title
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: root.query.length > 0 ? "󰍉" : root.currentCategoryIcon()
                                font.family: "Material Design Icons"
                                font.pixelSize: 16
                                color: root.cPrimary
                            }

                            Text {
                                text: root.query.length > 0
                                    ? `Results for "${root.query}"`
                                    : root.selectedCategory
                                font.family: root.config.appearance.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                color: root.cText
                            }

                            Rectangle {
                                Layout.preferredHeight: 18
                                Layout.preferredWidth: secCountText.implicitWidth + 10
                                radius: 5
                                color: Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.15)

                                Text {
                                    id: secCountText
                                    anchors.centerIn: parent
                                    text: `${root.currentBinds.length} shortcuts`
                                    font.family: root.config.appearance.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                    color: root.cPrimary
                                }
                            }

                            Item { Layout.fillWidth: true }
                        }

                        // Scrollable shortcuts list
                        Flickable {
                            id: bindFlickable
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            contentWidth: width
                            contentHeight: bindCol.height
                            boundsBehavior: Flickable.StopAtBounds

                            QQC.ScrollBar.vertical: QQC.ScrollBar {
                                policy: QQC.ScrollBar.AsNeeded
                            }

                            Column {
                                id: bindCol
                                width: bindFlickable.width - 8
                                spacing: 6

                                Repeater {
                                    model: root.currentBinds

                                    Rectangle {
                                        id: rowCard
                                        required property var modelData
                                        required property int index

                                        width: bindCol.width
                                        height: 48
                                        radius: 12

                                        color: rowHover.hovered
                                            ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.09)
                                            : (index % 2 === 0 ? Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.03) : "transparent")

                                        border.width: 1
                                        border.color: rowHover.hovered
                                            ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.35)
                                            : Qt.rgba(root.cBorder.r, root.cBorder.g, root.cBorder.b, 0.20)

                                        Behavior on color { ColorAnimation { duration: 120 } }
                                        Behavior on border.color { ColorAnimation { duration: 120 } }

                                        HoverHandler { id: rowHover }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 14
                                            anchors.rightMargin: 14
                                            spacing: 16

                                            // Key Badge Chip
                                            Rectangle {
                                                Layout.preferredHeight: 30
                                                Layout.preferredWidth: keyLabel.implicitWidth + 22
                                                radius: 8
                                                color: rowHover.hovered
                                                    ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.25)
                                                    : Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.12)
                                                border.width: 1
                                                border.color: rowHover.hovered
                                                    ? root.cPrimary
                                                    : Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.30)

                                                Behavior on color { ColorAnimation { duration: 120 } }

                                                Text {
                                                    id: keyLabel
                                                    anchors.centerIn: parent
                                                    text: rowCard.modelData.key
                                                    font.family: "JetBrains Mono, monospace"
                                                    font.pixelSize: 12
                                                    font.weight: Font.DemiBold
                                                    color: root.cPrimary
                                                }
                                            }

                                            // Action Description
                                            Text {
                                                Layout.fillWidth: true
                                                text: rowCard.modelData.action
                                                font.family: root.config.appearance.fontFamily
                                                font.pixelSize: 13
                                                font.weight: Font.Normal
                                                color: root.cText
                                                elide: Text.ElideRight
                                            }

                                            // Category badge (visible when searching)
                                            Rectangle {
                                                visible: root.query.length > 0
                                                Layout.preferredHeight: 22
                                                Layout.preferredWidth: catTagText.implicitWidth + 12
                                                radius: 6
                                                color: Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.08)

                                                Text {
                                                    id: catTagText
                                                    anchors.centerIn: parent
                                                    text: rowCard.modelData.cat
                                                    font.family: root.config.appearance.fontFamily
                                                    font.pixelSize: 10
                                                    color: root.cSubText
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Empty State
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: root.currentBinds.length === 0

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "󰍉"
                                    font.family: "Material Design Icons"
                                    font.pixelSize: 36
                                    color: root.cSubText
                                    opacity: 0.5
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: `No shortcuts matching "${root.query}"`
                                    font.family: root.config.appearance.fontFamily
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    color: root.cText
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "Try searching for a different keyword or key name"
                                    font.family: root.config.appearance.fontFamily
                                    font.pixelSize: 11
                                    color: root.cSubText
                                }
                            }
                        }
                    }
                }

                // Visual Keyboard View
                KeyboardMapView {
                    id: keyboardMap
                    visible: root.viewMode === "keyboard"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    allBinds: root.allBinds
                    keyboardInfo: root.keyboardInfo
                    searchQuery: root.query
                    liveMods: root.liveMods
                    cSurface: root.cSurface
                    cDeck: root.cDeck
                    cContainer: root.cContainer
                    cContainerLow: root.cContainerLow
                    cContainerHigh: root.cContainerHigh
                    cPrimary: root.cPrimary
                    cOnPrimary: root.cOnPrimary
                    cPrimaryContainer: root.cPrimaryContainer
                    cOnPrimaryContainer: root.cOnPrimaryContainer
                    cText: root.cText
                    cSubText: root.cSubText
                    cBorder: root.cBorder
                    cWarning: root.pywal.warning
                    cOnWarning: root.pywal.m3onWarning
                    cSuccess: root.pywal.success
                    isLight: root.pywal.isLight
                    fontFamily: root.config.appearance.fontFamily
                }

                // Bottom Footer Hints
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    spacing: 16

                    Item { Layout.fillWidth: true }

                    RowLayout {
                        spacing: 4
                        Rectangle {
                            width: 48; height: 18; radius: 4
                            color: Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.10)
                            Text { anchors.centerIn: parent; text: "Ctrl+Tab"; font.pixelSize: 9; color: root.cSubText }
                        }
                        Text { text: root.viewMode === "keyboard" ? "Seznam" : "Klávesnice"; font.family: root.config.appearance.fontFamily; font.pixelSize: 11; color: root.cSubText }
                    }

                    RowLayout {
                        visible: root.viewMode === "list"
                        spacing: 4
                        Rectangle {
                            width: 26; height: 18; radius: 4
                            color: Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.10)
                            Text { anchors.centerIn: parent; text: "↑↓"; font.pixelSize: 10; color: root.cSubText }
                        }
                        Text { text: "Change Category"; font.family: root.config.appearance.fontFamily; font.pixelSize: 11; color: root.cSubText }
                    }

                    RowLayout {
                        visible: root.viewMode === "list"
                        spacing: 4
                        Rectangle {
                            width: 28; height: 18; radius: 4
                            color: Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.10)
                            Text { anchors.centerIn: parent; text: "Tab"; font.pixelSize: 9; color: root.cSubText }
                        }
                        Text { text: "Next Category"; font.family: root.config.appearance.fontFamily; font.pixelSize: 11; color: root.cSubText }
                    }

                    RowLayout {
                        visible: root.viewMode === "keyboard"
                        spacing: 4
                        Rectangle {
                            width: 44; height: 18; radius: 4
                            color: Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.10)
                            Text { anchors.centerIn: parent; text: "Klik"; font.pixelSize: 9; color: root.cSubText }
                        }
                        Text { text: "Připnout klávesu / modifikátor"; font.family: root.config.appearance.fontFamily; font.pixelSize: 11; color: root.cSubText }
                    }

                    RowLayout {
                        spacing: 4
                        Rectangle {
                            width: 28; height: 18; radius: 4
                            color: Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.10)
                            Text { anchors.centerIn: parent; text: "Esc"; font.pixelSize: 9; color: root.cSubText }
                        }
                        Text { text: "Close"; font.family: root.config.appearance.fontFamily; font.pixelSize: 11; color: root.cSubText }
                    }
                }
            }
        }
    }
}

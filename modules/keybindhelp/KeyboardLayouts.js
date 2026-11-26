.pragma library

// Physical keyboard layout definitions in standard 1u key units.
// Supports Lenovo IdeaPad Gaming 3 15ARH7 (auto-detected), TKL (80%), and 75% Compact,
// each with Czech (QWERTZ ISO) and US (QWERTY ANSI) legends.

const PROFILES = [
    { id: "ideapad-gaming-3", label: "IdeaPad Gaming 3", shortLabel: "IdeaPad G3" },
    { id: "tkl", label: "TKL 80%", shortLabel: "TKL" },
    { id: "compact-75", label: "Compact 75%", shortLabel: "75%" }
]

const MOUSE_CONTROLS = [
    { id: "MouseLeft", label: "L-Drag", icon: "󰍽", sub: "Left" },
    { id: "MouseRight", label: "R-Drag", icon: "󰍽", sub: "Right" },
    { id: "MouseWheelUp", label: "Scroll ↑", icon: "󰞕", sub: "Wheel" },
    { id: "MouseWheelDown", label: "Scroll ↓", icon: "󰞒", sub: "Wheel" }
]

function _k(id, label, x, y, w, h, opts) {
    const o = opts || {}
    return {
        id: id,
        label: label,
        sub: o.sub || "",
        x: x,
        y: y,
        w: w || 1.0,
        h: h || 1.0,
        mod: o.mod || "",
        fnIds: o.fnIds || [],
        isoEnter: !!o.isoEnter,
        compact: !!o.compact
    }
}

function _alphaBlock(y0, isCz, isIso, rShiftW, hasRightColArrows) {
    const keys = []

    // Row 1: Number row (15.0u total)
    const numKeys = isCz
        ? [
            ["Grave", ";", "°"], ["1", "1", "+"], ["2", "2", "ě"], ["3", "3", "š"],
            ["4", "4", "č"], ["5", "5", "ř"], ["6", "6", "ž"], ["7", "7", "ý"],
            ["8", "8", "á"], ["9", "9", "í"], ["0", "0", "é"], ["Equal", "=", "%"], ["Acute", "´", "ˇ"]
        ]
        : [
            ["Grave", "`", "~"], ["1", "1", "!"], ["2", "2", "@"], ["3", "3", "#"],
            ["4", "4", "$"], ["5", "5", "%"], ["6", "6", "^"], ["7", "7", "&"],
            ["8", "8", "*"], ["9", "9", "("], ["0", "0", ")"], ["Minus", "-", "_"], ["Equal", "=", "+"]
        ]

    let x = 0
    for (let i = 0; i < numKeys.length; i++) {
        keys.push(_k(numKeys[i][0], numKeys[i][1], x, y0, 1.0, 1.0, { sub: numKeys[i][2] }))
        x += 1.0
    }
    keys.push(_k("Backspace", "Bksp", x, y0, 2.0, 1.0))

    // Row 2: QWERTZ / QWERTY (15.0u total)
    const y2 = y0 + 1.05
    const r2Letters = isCz
        ? ["Q", "W", "E", "R", "T", "Z", "U", "I", "O", "P"]
        : ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]
    const r2Punct = isCz
        ? [["BracketLeft", "ú", "/"], ["BracketRight", ")", "("]]
        : [["BracketLeft", "[", "{"], ["BracketRight", "]", "}"]]

    x = 0
    keys.push(_k("Tab", "Tab", x, y2, 1.5, 1.0))
    x += 1.5
    for (let i = 0; i < r2Letters.length; i++) {
        keys.push(_k(r2Letters[i], r2Letters[i], x, y2, 1.0, 1.0))
        x += 1.0
    }
    for (let i = 0; i < r2Punct.length; i++) {
        keys.push(_k(r2Punct[i][0], r2Punct[i][1], x, y2, 1.0, 1.0, { sub: r2Punct[i][2] }))
        x += 1.0
    }
    if (isIso) {
        // Tall L-shaped ISO Enter spanning Row 2 + Row 3
        keys.push(_k("Return", "Enter", x, y2, 1.5, 2.05, { isoEnter: true }))
    } else {
        keys.push(_k("Backslash", "\\", x, y2, 1.5, 1.0, { sub: "|" }))
    }

    // Row 3: Home row (15.0u total)
    const y3 = y0 + 2.10
    const r3Letters = ["A", "S", "D", "F", "G", "H", "J", "K", "L"]
    const r3Punct = isCz
        ? (isIso
            ? [["Semicolon", "ů", "\""], ["Apostrophe", "§", "!"], ["IsoHash", "¨", "'"]]
            : [["Semicolon", "ů", "\""], ["Apostrophe", "§", "!"]])
        : (isIso
            ? [["Semicolon", ";", ":"], ["Apostrophe", "'", "\""], ["IsoHash", "#", "~"]]
            : [["Semicolon", ";", ":"], ["Apostrophe", "'", "\""]])

    x = 0
    keys.push(_k("CapsLock", "Caps", x, y3, 1.75, 1.0))
    x += 1.75
    for (let i = 0; i < r3Letters.length; i++) {
        keys.push(_k(r3Letters[i], r3Letters[i], x, y3, 1.0, 1.0))
        x += 1.0
    }
    for (let i = 0; i < r3Punct.length; i++) {
        keys.push(_k(r3Punct[i][0], r3Punct[i][1], x, y3, 1.0, 1.0, { sub: r3Punct[i][2] }))
        x += 1.0
    }
    if (!isIso) {
        keys.push(_k("Return", "Enter", x, y3, 2.25, 1.0))
    }

    // Row 4: Bottom alpha row
    const y4 = y0 + 3.15
    const r4Letters = isCz
        ? ["Y", "X", "C", "V", "B", "N", "M"]
        : ["Z", "X", "C", "V", "B", "N", "M"]
    const r4Punct = isCz
        ? [["Comma", ",", "?"], ["Period", ".", ":"], ["Slash", "-", "_"]]
        : [["Comma", ",", "<"], ["Period", ".", ">"], ["Slash", "/", "?"]]

    x = 0
    if (isIso) {
        keys.push(_k("Shift_L", "Shift", x, y4, 1.25, 1.0, { mod: "Shift" }))
        x += 1.25
        keys.push(_k("IsoBackslash", "\\", x, y4, 1.0, 1.0, { sub: "|" }))
        x += 1.0
    } else {
        keys.push(_k("Shift_L", "Shift", x, y4, 2.25, 1.0, { mod: "Shift" }))
        x += 2.25
    }
    for (let i = 0; i < r4Letters.length; i++) {
        keys.push(_k(r4Letters[i], r4Letters[i], x, y4, 1.0, 1.0))
        x += 1.0
    }
    for (let i = 0; i < r4Punct.length; i++) {
        keys.push(_k(r4Punct[i][0], r4Punct[i][1], x, y4, 1.0, 1.0, { sub: r4Punct[i][2] }))
        x += 1.0
    }
    keys.push(_k("Shift_R", "Shift", x, y4, rShiftW, 1.0, { mod: "Shift" }))

    return keys
}

function _buildIdeaPadGaming3(isCz, isIso) {
    // Authentic Lenovo IdeaPad Gaming 3 15ARH7 (82SB) layout:
    // Compact Fn/Media row + ISO/ANSI main block + dropped full-size inverted-T arrows + 4-col Numpad
    const keys = []
    const fnH = 0.78
    const yMain = 0.94

    // Top row: Esc + F1..F12 (with Fn media/brightness bindings) + Ins + PrtSc + Del = 15.0u
    keys.push(_k("Escape", "Esc", 0, 0, 1.0, fnH, { compact: true }))
    const fnSpecs = [
        ["F1", "F1", "󰝟", ["AudioMute"]],
        ["F2", "F2", "󰕿", ["VolumeDown"]],
        ["F3", "F3", "󰕾", ["VolumeUp"]],
        ["F4", "F4", "󰍭", ["MicMute"]],
        ["F5", "F5", "󰃞", ["BrightnessDown"]],
        ["F6", "F6", "󰃠", ["BrightnessUp"]],
        ["F7", "F7", "", []],
        ["F8", "F8", "", []],
        ["F9", "F9", "", []],
        ["F10", "F10", "", []],
        ["F11", "F11", "", []],
        ["F12", "F12", "", []]
    ]
    const fW = 11.04 / 12.0
    for (let i = 0; i < fnSpecs.length; i++) {
        keys.push(_k(fnSpecs[i][0], fnSpecs[i][1], 1.0 + i * fW, 0, fW, fnH, {
            sub: fnSpecs[i][2],
            fnIds: fnSpecs[i][3],
            compact: true
        }))
    }
    keys.push(_k("Insert", "Ins", 12.04, 0, 0.96, fnH, { compact: true }))
    keys.push(_k("Print", "PrtSc", 13.0, 0, 1.0, fnH, { compact: true }))
    keys.push(_k("Delete", "Del", 14.0, 0, 1.0, fnH, { compact: true }))

    // Main block (RShift 1.75u to create the IdeaPad Gaming 3 offset arrow cutout)
    const alpha = _alphaBlock(yMain, isCz, isIso, 1.75, true)
    for (let i = 0; i < alpha.length; i++) keys.push(alpha[i])

    // Bottom modifier row (y = yMain + 4.20 = 5.14)
    const yBot = yMain + 4.20
    keys.push(_k("Control_L", "Ctrl", 0.0, yBot, 1.25, 1.0, { mod: "Ctrl" }))
    keys.push(_k("Fn", "Fn", 1.25, yBot, 1.0, 1.0))
    keys.push(_k("Super_L", "Super", 2.25, yBot, 1.0, 1.0, { mod: "Super" }))
    keys.push(_k("Alt_L", "Alt", 3.25, yBot, 1.25, 1.0, { mod: "Alt" }))
    keys.push(_k("Space", "Space", 4.50, yBot, 6.25, 1.0))
    keys.push(_k("Alt_R", "AltGr", 10.75, yBot, 1.0, 1.0, { mod: "Alt" }))
    keys.push(_k("Control_R", "Ctrl", 11.75, yBot, 1.0, 1.0, { mod: "Ctrl" }))

    // Signature Lenovo IdeaPad Gaming 3 dropped full-size inverted-T arrow cluster
    const arrowOffset = 0.22
    keys.push(_k("Up", "↑", 14.0, yMain + 3.15 + arrowOffset, 1.0, 1.0))
    keys.push(_k("Left", "←", 13.0, yBot + arrowOffset, 1.0, 1.0))
    keys.push(_k("Down", "↓", 14.0, yBot + arrowOffset, 1.0, 1.0))
    keys.push(_k("Right", "→", 15.0, yBot + arrowOffset, 1.0, 1.0))

    // Right 4-column Numpad (starts at x = 16.30)
    const nx = 16.30
    // Top media strip above Numpad
    keys.push(_k("MediaPlay", "󰐊", nx + 0.0, 0, 1.0, fnH, { fnIds: ["MediaPause"], compact: true, sub: "Play" }))
    keys.push(_k("MediaStop", "󰓛", nx + 1.0, 0, 1.0, fnH, { compact: true, sub: "Stop" }))
    keys.push(_k("MediaPrev", "󰒮", nx + 2.0, 0, 1.0, fnH, { compact: true, sub: "Prev" }))
    keys.push(_k("MediaNext", "󰒭", nx + 3.0, 0, 1.0, fnH, { compact: true, sub: "Next" }))

    // Numpad rows
    keys.push(_k("NumLock", "Num", nx + 0.0, yMain, 1.0, 1.0))
    keys.push(_k("KP_Divide", "/", nx + 1.0, yMain, 1.0, 1.0))
    keys.push(_k("KP_Multiply", "*", nx + 2.0, yMain, 1.0, 1.0))
    keys.push(_k("KP_Subtract", "-", nx + 3.0, yMain, 1.0, 1.0))

    keys.push(_k("KP_7", "7", nx + 0.0, yMain + 1.05, 1.0, 1.0, { sub: "Home" }))
    keys.push(_k("KP_8", "8", nx + 1.0, yMain + 1.05, 1.0, 1.0))
    keys.push(_k("KP_9", "9", nx + 2.0, yMain + 1.05, 1.0, 1.0, { sub: "PgUp" }))
    keys.push(_k("KP_Add", "+", nx + 3.0, yMain + 1.05, 1.0, 2.05))

    keys.push(_k("KP_4", "4", nx + 0.0, yMain + 2.10, 1.0, 1.0))
    keys.push(_k("KP_5", "5", nx + 1.0, yMain + 2.10, 1.0, 1.0))
    keys.push(_k("KP_6", "6", nx + 2.0, yMain + 2.10, 1.0, 1.0))

    keys.push(_k("KP_1", "1", nx + 0.0, yMain + 3.15, 1.0, 1.0, { sub: "End" }))
    keys.push(_k("KP_2", "2", nx + 1.0, yMain + 3.15, 1.0, 1.0))
    keys.push(_k("KP_3", "3", nx + 2.0, yMain + 3.15, 1.0, 1.0, { sub: "PgDn" }))
    keys.push(_k("KP_Enter", "Ent", nx + 3.0, yMain + 3.15, 1.0, 2.05))

    keys.push(_k("KP_0", "0", nx + 0.0, yBot, 2.0, 1.0, { sub: "Ins" }))
    keys.push(_k("KP_Decimal", ",", nx + 2.0, yBot, 1.0, 1.0, { sub: "Del" }))

    return {
        keys: keys,
        totalWidth: 20.30,
        totalHeight: yBot + arrowOffset + 1.0
    }
}

function _buildTkl(isCz, isIso) {
    const keys = []
    const fnH = 0.88
    const yMain = 1.15

    // Function row
    keys.push(_k("Escape", "Esc", 0.0, 0, 1.0, fnH, { compact: true }))
    const fnGroups = [
        { start: 2.0, keys: ["F1", "F2", "F3", "F4"], fns: [["AudioMute"], ["VolumeDown"], ["VolumeUp"], ["MicMute"]] },
        { start: 6.5, keys: ["F5", "F6", "F7", "F8"], fns: [["BrightnessDown"], ["BrightnessUp"], ["MediaPrev"], ["MediaPlay", "MediaPause"]] },
        { start: 11.0, keys: ["F9", "F10", "F11", "F12"], fns: [["MediaNext"], ["MediaStop"], [], []] }
    ]
    for (let g = 0; g < fnGroups.length; g++) {
        const grp = fnGroups[g]
        for (let i = 0; i < grp.keys.length; i++) {
            keys.push(_k(grp.keys[i], grp.keys[i], grp.start + i, 0, 1.0, fnH, {
                fnIds: grp.fns[i],
                compact: true
            }))
        }
    }

    const alpha = _alphaBlock(yMain, isCz, isIso, 2.75, false)
    for (let i = 0; i < alpha.length; i++) keys.push(alpha[i])

    const yBot = yMain + 4.20
    keys.push(_k("Control_L", "Ctrl", 0.0, yBot, 1.25, 1.0, { mod: "Ctrl" }))
    keys.push(_k("Super_L", "Super", 1.25, yBot, 1.25, 1.0, { mod: "Super" }))
    keys.push(_k("Alt_L", "Alt", 2.50, yBot, 1.25, 1.0, { mod: "Alt" }))
    keys.push(_k("Space", "Space", 3.75, yBot, 6.25, 1.0))
    keys.push(_k("Alt_R", isCz ? "AltGr" : "Alt", 10.0, yBot, 1.25, 1.0, { mod: "Alt" }))
    keys.push(_k("Super_R", "Super", 11.25, yBot, 1.25, 1.0, { mod: "Super" }))
    keys.push(_k("Menu", "Fn", 12.50, yBot, 1.25, 1.0))
    keys.push(_k("Control_R", "Ctrl", 13.75, yBot, 1.25, 1.0, { mod: "Ctrl" }))

    // Nav + Arrow cluster (x = 15.35)
    const nx = 15.35
    keys.push(_k("Print", "PrtSc", nx + 0, 0, 1.0, fnH, { compact: true }))
    keys.push(_k("ScrollLock", "ScrLk", nx + 1, 0, 1.0, fnH, { compact: true }))
    keys.push(_k("Pause", "Pause", nx + 2, 0, 1.0, fnH, { compact: true }))

    keys.push(_k("Insert", "Ins", nx + 0, yMain, 1.0, 1.0))
    keys.push(_k("Home", "Home", nx + 1, yMain, 1.0, 1.0))
    keys.push(_k("PageUp", "PgUp", nx + 2, yMain, 1.0, 1.0))

    keys.push(_k("Delete", "Del", nx + 0, yMain + 1.05, 1.0, 1.0))
    keys.push(_k("End", "End", nx + 1, yMain + 1.05, 1.0, 1.0))
    keys.push(_k("PageDown", "PgDn", nx + 2, yMain + 1.05, 1.0, 1.0))

    keys.push(_k("Up", "↑", nx + 1, yMain + 3.15, 1.0, 1.0))
    keys.push(_k("Left", "←", nx + 0, yBot, 1.0, 1.0))
    keys.push(_k("Down", "↓", nx + 1, yBot, 1.0, 1.0))
    keys.push(_k("Right", "→", nx + 2, yBot, 1.0, 1.0))

    return {
        keys: keys,
        totalWidth: 18.35,
        totalHeight: yBot + 1.0
    }
}

function _buildCompact75(isCz, isIso) {
    const keys = []
    const fnH = 0.85
    const yMain = 1.00

    keys.push(_k("Escape", "Esc", 0.0, 0, 1.0, fnH, { compact: true }))
    const fnMedia = [
        ["AudioMute"], ["VolumeDown"], ["VolumeUp"], ["MicMute"],
        ["BrightnessDown"], ["BrightnessUp"], ["MediaPrev"], ["MediaPlay", "MediaPause"],
        ["MediaNext"], ["MediaStop"], [], []
    ]
    for (let i = 0; i < 12; i++) {
        keys.push(_k(`F${i + 1}`, `F${i + 1}`, 1.0 + i, 0, 1.0, fnH, {
            fnIds: fnMedia[i],
            compact: true
        }))
    }
    keys.push(_k("Print", "PrtSc", 13.0, 0, 1.0, fnH, { compact: true }))
    keys.push(_k("Insert", "Ins", 14.0, 0, 1.0, fnH, { compact: true }))
    keys.push(_k("Delete", "Del", 15.0, 0, 1.0, fnH, { compact: true }))

    const alpha = _alphaBlock(yMain, isCz, isIso, 1.75, true)
    for (let i = 0; i < alpha.length; i++) keys.push(alpha[i])

    // Right nav column at x = 15.0
    keys.push(_k("Home", "Home", 15.0, yMain, 1.0, 1.0))
    keys.push(_k("PageUp", "PgUp", 15.0, yMain + 1.05, 1.0, 1.0))
    keys.push(_k("PageDown", "PgDn", 15.0, yMain + 2.10, 1.0, 1.0))
    keys.push(_k("End", "End", 15.0, yMain + 3.15, 1.0, 1.0))
    keys.push(_k("Up", "↑", 14.0, yMain + 3.15, 1.0, 1.0))

    const yBot = yMain + 4.20
    keys.push(_k("Control_L", "Ctrl", 0.0, yBot, 1.25, 1.0, { mod: "Ctrl" }))
    keys.push(_k("Super_L", "Super", 1.25, yBot, 1.25, 1.0, { mod: "Super" }))
    keys.push(_k("Alt_L", "Alt", 2.50, yBot, 1.25, 1.0, { mod: "Alt" }))
    keys.push(_k("Space", "Space", 3.75, yBot, 6.25, 1.0))
    keys.push(_k("Alt_R", isCz ? "AltGr" : "Alt", 10.0, yBot, 1.0, 1.0, { mod: "Alt" }))
    keys.push(_k("Fn", "Fn", 11.0, yBot, 1.0, 1.0))
    keys.push(_k("Control_R", "Ctrl", 12.0, yBot, 1.0, 1.0, { mod: "Ctrl" }))
    keys.push(_k("Left", "←", 13.0, yBot, 1.0, 1.0))
    keys.push(_k("Down", "↓", 14.0, yBot, 1.0, 1.0))
    keys.push(_k("Right", "→", 15.0, yBot, 1.0, 1.0))

    return {
        keys: keys,
        totalWidth: 16.0,
        totalHeight: yBot + 1.0
    }
}

function buildLayout(profileId, layoutCode) {
    const isCz = (layoutCode || "cz").toLowerCase().startsWith("cz")
    const isIso = isCz
    if (profileId === "tkl") return _buildTkl(isCz, isIso)
    if (profileId === "compact-75") return _buildCompact75(isCz, isIso)
    return _buildIdeaPadGaming3(isCz, isIso)
}

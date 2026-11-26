#!/usr/bin/env python3
"""Extract Hyprland / Hyprlua keybinds and generate human-readable descriptions."""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from pathlib import Path

CATEGORY_META = [
    ("Applications", "󰀻"),
    ("Window Management", "󱂬"),
    ("Navigation & Switching", "󰜙"),
    ("Workspaces", "󰮌"),
    ("System & Session", "󰒓"),
    ("Resize Mode", "󰔲"),
    ("Media & Hardware", "󰝚"),
    ("Groups & Tabs", "󰓩"),
    ("Screenshots", "󰄄"),
    ("Mouse Controls", "󰍽"),
]

CATEGORY_ALIASES = {
    "applications": "Applications",
    "apps": "Applications",
    "window management": "Window Management",
    "window switching": "Navigation & Switching",
    "focus movement": "Navigation & Switching",
    "move window": "Navigation & Switching",
    "swap window": "Navigation & Switching",
    "workspaces": "Workspaces",
    "special workspaces": "Workspaces",
    "mouse controls": "Mouse Controls",
    "system": "System & Session",
    "session": "System & Session",
    "extras": "System & Session",
    "resize submap": "Resize Mode",
    "resize mode": "Resize Mode",
    "media keys": "Media & Hardware",
    "media": "Media & Hardware",
    "tiling": "Groups & Tabs",
    "groups": "Groups & Tabs",
    "screenshots": "Screenshots",
}

KEY_ALIASES = {
    "super": "Super",
    "mainmod": "Super",
    "ctrl": "Ctrl",
    "control": "Ctrl",
    "shift": "Shift",
    "alt": "Alt",
    "mod1": "Alt",
    "mod4": "Super",
    "return": "Return",
    "space": "Space",
    "tab": "Tab",
    "escape": "Escape",
    "comma": ",",
    "period": ".",
    "left": "Left",
    "right": "Right",
    "up": "Up",
    "down": "Down",
    "caps_lock": "CapsLock",
    "print": "Print",
    "mouse_down": "Mouse Wheel Down",
    "mouse_up": "Mouse Wheel Up",
    "mouse:272": "Left Drag",
    "mouse:273": "Right Drag",
    "code:49": "; (pod Esc)",
    "xf86audioraisevolume": "Volume Up",
    "xf86audiolowervolume": "Volume Down",
    "xf86audiomute": "Audio Mute",
    "xf86audiomicmute": "Mic Mute",
    "xf86monbrightnessup": "Brightness Up",
    "xf86monbrightnessdown": "Brightness Down",
    "xf86audioplay": "Media Play",
    "xf86audiopause": "Media Pause",
    "xf86audiostop": "Media Stop",
    "xf86audionext": "Next Track",
    "xf86audioprev": "Previous Track",
}

DIR_NAMES = {"l": "Left", "r": "Right", "u": "Up", "d": "Down"}

APP_NAMES = {
    "kitty": "Open Terminal (Kitty)",
    "alacritty": "Open Terminal (Alacritty)",
    "foot": "Open Terminal (Foot)",
    "wezterm": "Open Terminal (WezTerm)",
    "dolphin": "Open File Manager (Dolphin)",
    "thunar": "Open File Manager (Thunar)",
    "nautilus": "Open File Manager (Nautilus)",
    "librewolf": "Open Web Browser (LibreWolf)",
    "firefox": "Open Web Browser (Firefox)",
    "chromium": "Open Web Browser (Chromium)",
    "obsidian": "Open Obsidian",
    "equibop": "Open Equibop",
    "vicinae toggle": "Application Launcher (Vicinae)",
}

EXEC_PATTERNS = [
    (r"open_picker\.sh", "Wallpaper Picker"),
    (r"hypr-settings\.sh", "Hyprland Session Settings"),
    (r"scratchpad-term\.sh\s+magic-toggle", "Toggle Magic Scratchpad"),
    (r"scratchpad-term\.sh\s+magic-move", "Send Window to Magic Scratchpad"),
    (r"scratchpad-term\.sh\s+toggle", "Toggle Terminal Scratchpad"),
    (r"scratchpad-term\.sh\s+move", "Send Window to Terminal Scratchpad"),
    (r"toggle-pear\.sh", "Toggle YouTube Music (Pear)"),
    (r"bongo-focus\.sh", "Toggle BongoCat Interactive Focus"),
    (r"vicinae\s+cmd\s+launch\s+wm:switch-windows", "Visual Window Switcher (Vicinae)"),
    (r"vicinae://launch/clipboard/history", "Clipboard History (Vicinae)"),
    (r"screenshot\s+region", "Interactive Region Screenshot"),
    (r"screenshot\s+full", "Capture Fullscreen Screenshot"),
    (r"screenshot\s+window", "Capture Active Window Screenshot"),
    (r"satty\s+--filename", "Open Last Screenshot in Satty Editor"),
    (r"wpctl\s+set-volume.*5%\+", "Adjust Output Volume +5% (wpctl)"),
    (r"wpctl\s+set-volume.*5%-", "Adjust Output Volume -5% (wpctl)"),
    (r"wpctl\s+set-mute.*DEFAULT_AUDIO_SINK", "Toggle Audio Mute (wpctl)"),
    (r"wpctl\s+set-mute.*DEFAULT_AUDIO_SOURCE", "Toggle Microphone Mute (wpctl)"),
    (r"brightnessctl\s+set\s+5%\+", "Adjust Display Brightness +5%"),
    (r"brightnessctl\s+set\s+5%-", "Adjust Display Brightness -5%"),
    (r"media-ctl\.sh\s+play-pause", "Toggle Media Play / Pause"),
    (r"media-ctl\.sh\s+stop", "Stop Media Playback"),
    (r"media-ctl\.sh\s+next", "Next Media Track"),
    (r"media-ctl\.sh\s+previous", "Previous Media Track"),
    (r"changegroupactive\s+f", "Next Tab in Active Group"),
    (r"changegroupactive\s+b", "Previous Tab in Active Group"),
    (r"ipc\s+call\s+lock\s+lock", "Lock Screen"),
    (r"ipc\s+call\s+keybindhelp\s+toggle", "Keybind Reference (This Panel)"),
    (r"ipc\s+call\s+(?:drawers\s+toggle\s+sidebar|sidebar\s+toggle)", "Toggle Notification Center / Sidebar"),
    (r"hyprctl\s+reload", "Reload Hyprland Config"),
    (r"hyprctl\s+dispatch\s+exit", "Exit Hyprland Session"),
    (r"xdotool\s+key\s+Caps_Lock", "Toggle Caps Lock"),
]


def format_key_combo(raw_key: str) -> str:
    """Normalize a key combination string such as 'SUPER + SHIFT + left'."""
    parts = [p.strip() for p in re.split(r"\s*\+\s*", raw_key.strip()) if p.strip()]
    out = []
    for p in parts:
        low = p.lower()
        if low in KEY_ALIASES:
            out.append(KEY_ALIASES[low])
        elif len(p) == 1:
            out.append(p.upper())
        else:
            out.append(p)
    return " + ".join(out)


def infer_category(section: str, key: str, action_expr: str, submap: str) -> str:
    """Resolve a human category from section header, submap, key, and action."""
    if submap == "resize":
        return "Resize Mode"
    sec_low = section.lower()
    for needle, cat in CATEGORY_ALIASES.items():
        if needle in sec_low:
            return cat
    low_act = action_expr.lower()
    low_key = key.lower()
    if "mouse" in low_key or "drag" in low_key:
        return "Mouse Controls"
    if "screenshot" in low_act or "satty" in low_act or "print" in low_key:
        return "Screenshots"
    if "group" in low_act:
        return "Groups & Tabs"
    if any(t in low_key for t in ("volume", "mute", "brightness", "media", "track")) or "wpctl" in low_act or "media-ctl" in low_act:
        return "Media & Hardware"
    if "workspace" in low_act or "scratchpad" in low_act:
        return "Workspaces"
    if any(t in low_act for t in ("focus", "cycle_next", "move({ direction", "swap({ direction")):
        return "Navigation & Switching"
    if "exec_cmd" in low_act:
        return "Applications"
    return "System & Session"


def resolve_lua_string(expr: str, lua_vars: dict[str, str]) -> str:
    """Evaluate simple Lua string literals and variable concatenations."""
    parts = [p.strip() for p in expr.split("..")]
    resolved = []
    for part in parts:
        if (part.startswith('"') and part.endswith('"')) or (part.startswith("'") and part.endswith("'")):
            resolved.append(part[1:-1])
        elif part in lua_vars:
            resolved.append(lua_vars[part])
        else:
            return expr.strip()
    return "".join(resolved)


def describe_action(action_expr: str, lua_vars: dict[str, str], inline_comment: str) -> tuple[str, bool]:
    """Generate a readable description and whether it is auxiliary/secondary."""
    if inline_comment:
        return inline_comment.strip(), False

    expr = action_expr.strip()
    is_aux = "alter_zorder" in expr or "caelestia-toast" in expr

    m_exec = re.match(r'^hl\.dsp\.exec_cmd\((.*)\)$', expr, re.S)
    if m_exec:
        cmd = resolve_lua_string(m_exec.group(1).strip(), lua_vars).strip()
        cmd_low = cmd.lower()
        if cmd_low in APP_NAMES:
            return APP_NAMES[cmd_low], is_aux
        for pat, desc in EXEC_PATTERNS:
            if re.search(pat, cmd):
                return desc, is_aux
        prog = os.path.basename(cmd.split()[0]) if cmd.split() else cmd
        return f"Run {prog}", is_aux

    if expr == "hl.dsp.window.close()":
        return "Close Focused Window", False
    if "hl.dsp.window.float" in expr:
        return "Toggle Floating Mode", False
    if expr == "hl.dsp.window.pin()":
        return "Pin Floating Window (Always on Top)", False
    if expr == "hl.dsp.window.pseudo()":
        return "Toggle Pseudo-tiling", False
    if "hl.dsp.window.fullscreen_state" in expr:
        return "Toggle Tiled Fullscreen", False
    if "hl.dsp.window.fullscreen" in expr:
        return "Toggle Fullscreen", False
    if 'hl.dsp.layout("togglesplit")' in expr:
        return "Toggle Split Direction", False
    if expr == "hl.dsp.window.center()":
        return "Center Floating Window", False
    if "hl.dsp.window.cycle_next" in expr:
        return ("Cycle Windows Backward" if "prev = true" in expr else "Cycle Windows"), False
    if "hl.dsp.window.drag" in expr:
        return "Move Window", False
    if "hl.dsp.window.resize" in expr:
        if "x =" in expr or "y =" in expr:
            mx = re.search(r"x\s*=\s*(-?\d+)", expr)
            my = re.search(r"y\s*=\s*(-?\d+)", expr)
            dx = int(mx.group(1)) if mx else 0
            dy = int(my.group(1)) if my else 0
            if dx > 0:
                return f"Resize Window Wider (+{dx}px)", False
            if dx < 0:
                return f"Resize Window Narrower ({dx}px)", False
            if dy < 0:
                return f"Resize Window Shorter ({dy}px)", False
            if dy > 0:
                return f"Resize Window Taller (+{dy}px)", False
        return "Resize Window", False
    if "focus_direction" in expr or "hl.dsp.focus" in expr:
        md = re.search(r'(?:direction\s*=\s*|focus_direction\()"([lrud])"', expr)
        if md:
            return f"Move Focus {DIR_NAMES[md.group(1)]}", False
        mw = re.search(r'workspace\s*=\s*"([^"]+)"', expr)
        if mw:
            ws = mw.group(1)
            if ws == "e+1":
                return "Next Workspace", False
            if ws == "e-1":
                return "Previous Workspace", False
            return f"Switch to Workspace {ws}", False
    if "hl.dsp.window.move" in expr:
        if "out_of_group = true" in expr:
            return "Move Window Out of Group", False
        md = re.search(r'direction\s*=\s*"([lrud])"', expr)
        if md:
            return f"Move Window {DIR_NAMES[md.group(1)]}", False
        mw = re.search(r'workspace\s*=\s*"([^"]+)"', expr)
        if mw:
            if "follow = false" in expr:
                return f"Move Window to Workspace {mw.group(1)} Silently", False
            return f"Move Window to Workspace {mw.group(1)}", False
    if "hl.dsp.window.swap" in expr:
        md = re.search(r'direction\s*=\s*"([lrud])"', expr)
        if md:
            return f"Swap Window {DIR_NAMES[md.group(1)]}", False
    if "hl.dsp.group.toggle" in expr:
        return "Toggle Window Group (Tabbed View)", False
    if 'hl.dsp.submap("reset")' in expr:
        return "Exit Resize Mode to Normal", False
    if 'hl.dsp.submap("resize")' in expr:
        return "Enter Interactive Resize Mode", False

    return expr, is_aux


def split_top_level_args(text: str) -> list[str]:
    """Split Lua function call arguments on top-level commas."""
    args = []
    cur = []
    depth_paren = 0
    depth_brace = 0
    in_quote = None
    escaped = False
    for ch in text:
        if escaped:
            cur.append(ch)
            escaped = False
            continue
        if ch == "\\" and in_quote:
            cur.append(ch)
            escaped = True
            continue
        if in_quote:
            cur.append(ch)
            if ch == in_quote:
                in_quote = None
            continue
        if ch in ('"', "'"):
            in_quote = ch
            cur.append(ch)
        elif ch == "(":
            depth_paren += 1
            cur.append(ch)
        elif ch == ")":
            depth_paren -= 1
            cur.append(ch)
        elif ch == "{":
            depth_brace += 1
            cur.append(ch)
        elif ch == "}":
            depth_brace -= 1
            cur.append(ch)
        elif ch == "," and depth_paren == 0 and depth_brace == 0:
            args.append("".join(cur).strip())
            cur = []
        else:
            cur.append(ch)
    if cur:
        args.append("".join(cur).strip())
    return args


def find_matching_paren(src: str, open_idx: int) -> int:
    """Find the index of the closing ')' matching '(' at open_idx."""
    depth = 0
    in_quote = None
    escaped = False
    for idx in range(open_idx, len(src)):
        ch = src[idx]
        if escaped:
            escaped = False
            continue
        if ch == "\\" and in_quote:
            escaped = True
            continue
        if in_quote:
            if ch == in_quote:
                in_quote = None
            continue
        if ch in ('"', "'"):
            in_quote = ch
        elif ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                return idx
    return -1


def parse_lua_file(path: Path) -> list[dict]:
    """Extract hl.bind entries from a Hyprlua file."""
    src = path.read_text(encoding="utf-8", errors="ignore")
    lua_vars: dict[str, str] = {}
    for m in re.finditer(r'^\s*local\s+([A-Za-z_]\w*)\s*=\s*"([^"]*)"', src, re.M):
        lua_vars[m.group(1)] = m.group(2)

    # Track section headings and submap regions by character offset
    section_events: list[tuple[int, str]] = []
    lines = src.splitlines(keepends=True)
    offset = 0
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith("-- ") and not set(stripped[3:]).issubset({"-", "="}):
            # Check if framed by dashed divider line above/below
            prev_s = lines[i - 1].strip() if i > 0 else ""
            next_s = lines[i + 1].strip() if i + 1 < len(lines) else ""
            if prev_s.startswith("-- ---") or next_s.startswith("-- ---"):
                section_events.append((offset, stripped[3:].strip()))
        offset += len(line)

    submap_ranges: list[tuple[int, int, str]] = []
    for m in re.finditer(r'hl\.define_submap\(\s*"([^"]+)"\s*,', src):
        open_p = src.find("(", m.start())
        close_p = find_matching_paren(src, open_p)
        if close_p != -1:
            submap_ranges.append((m.start(), close_p, m.group(1)))

    # Handle workspace code table loop cleanly if present
    has_ws_loop = bool(re.search(r"for\s+code,\s*id\s+in\s+pairs\(codes\)\s+do", src))

    results: list[dict] = []
    pos = 0
    for m in re.finditer(r"\bhl\.bind\s*\(", src):
        if m.start() < pos:
            continue
        open_p = m.end() - 1
        close_p = find_matching_paren(src, open_p)
        if close_p == -1:
            continue
        pos = close_p + 1
        inner = src[open_p + 1 : close_p]
        args = split_top_level_args(inner)
        if len(args) < 2:
            continue

        # Trailing inline comment on the closing line
        line_end = src.find("\n", close_p)
        if line_end == -1:
            line_end = len(src)
        tail = src[close_p + 1 : line_end]
        cm = re.search(r"--\s*(.+)$", tail)
        inline_comment = cm.group(1).strip() if cm else ""

        key_expr, act_expr = args[0], args[1]

        # Resolve active section & submap
        section = "General"
        for soff, sname in section_events:
            if soff < m.start():
                section = sname
            else:
                break
        submap = ""
        for s_start, s_end, sm_name in submap_ranges:
            if s_start <= m.start() <= s_end:
                submap = sm_name
                break

        # Special handling for workspace keycode loop
        if "code:" in key_expr and ".." in key_expr and has_ws_loop:
            if "CTRL" in key_expr:
                results.append({
                    "cat": "Workspaces",
                    "key": "Super + Ctrl + 1–5",
                    "action": "Move Window to Workspace 1–5 Silently",
                    "raw": act_expr,
                    "aux": False,
                })
            elif "SHIFT" in key_expr:
                results.append({
                    "cat": "Workspaces",
                    "key": "Super + Shift + 1–5",
                    "action": "Move Window to Workspace 1–5",
                    "raw": act_expr,
                    "aux": False,
                })
            else:
                results.append({
                    "cat": "Workspaces",
                    "key": "Super + 1–5",
                    "action": "Switch to Workspace 1–5",
                    "raw": act_expr,
                    "aux": False,
                })
            continue

        key_str = resolve_lua_string(key_expr, lua_vars)
        if not ((key_expr.startswith('"') and key_expr.endswith('"')) or (key_expr.startswith("'") and key_expr.endswith("'"))):
            continue
        formatted_key = format_key_combo(key_str)
        desc, is_aux = describe_action(act_expr, lua_vars, inline_comment)
        cat = infer_category(section, formatted_key, act_expr, submap)
        results.append({
            "cat": cat,
            "key": formatted_key,
            "action": desc,
            "raw": act_expr,
            "aux": is_aux,
        })

    return results


def parse_conf_file(path: Path) -> list[dict]:
    """Extract standard Hyprland bind/bindd entries from a .conf file."""
    results: list[dict] = []
    submap = ""
    section = "General"
    for line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        s = line.strip()
        if not s:
            continue
        if s.startswith("#"):
            hdr = s.lstrip("#").strip()
            if hdr and not set(hdr).issubset({"-", "="}):
                section = hdr
            continue
        if s.startswith("submap"):
            val = s.split("=", 1)[1].strip() if "=" in s else ""
            submap = "" if val in ("", "reset") else val
            continue
        m = re.match(r"^bind([a-z]*)\s*=\s*(.+)$", s)
        if not m:
            continue
        flags, body = m.group(1), m.group(2)
        inline_comment = ""
        if "#" in body:
            body, inline_comment = body.split("#", 1)
            inline_comment = inline_comment.strip()
        parts = [p.strip() for p in body.split(",")]
        if len(parts) < 3:
            continue
        mods, key = parts[0], parts[1]
        if "d" in flags and len(parts) >= 4:
            desc = parts[2]
            dispatcher = parts[3]
            arg = ",".join(parts[4:]).strip()
        else:
            desc = inline_comment
            dispatcher = parts[2]
            arg = ",".join(parts[3:]).strip()
        combo = f"{mods} + {key}" if mods else key
        formatted_key = format_key_combo(combo)
        action_text = desc or f"{dispatcher} {arg}".strip()
        cat = infer_category(section, formatted_key, action_text, submap)
        results.append({
            "cat": cat,
            "key": formatted_key,
            "action": action_text,
            "raw": action_text,
            "aux": False,
        })
    return results


def modmask_to_str(mask: int) -> str:
    """Convert Hyprland modmask bitfield to modifier prefix."""
    mods = []
    if mask & 64:
        mods.append("Super")
    if mask & 4:
        mods.append("Ctrl")
    if mask & 8:
        mods.append("Alt")
    if mask & 1:
        mods.append("Shift")
    return " + ".join(mods)


def parse_hyprctl_binds() -> list[dict]:
    """Fallback runtime extraction via hyprctl binds -j for non-Hyprlua configs."""
    try:
        out = subprocess.check_output(["hyprctl", "binds", "-j"], text=True, timeout=2)
        data = json.loads(out)
    except Exception:
        return []

    results: list[dict] = []
    for b in data:
        disp = b.get("dispatcher", "")
        if disp.startswith(("HL.Dispatcher", "function:")):
            continue
        mods = modmask_to_str(int(b.get("modmask", 0)))
        key = b.get("key") or (f"code:{b['keycode']}" if b.get("keycode") else "")
        combo = format_key_combo(f"{mods} + {key}" if mods else key)
        desc = (b.get("description") or "").strip()
        arg = (b.get("arg") or "").strip()
        action = desc or (f"{disp} {arg}".strip() if arg else disp)
        submap = b.get("submap", "")
        results.append({
            "cat": infer_category("", combo, action, submap),
            "key": combo,
            "action": action,
            "raw": action,
            "aux": False,
        })
    return results


def _read_dmi(field: str) -> str:
    try:
        return Path(f"/sys/devices/virtual/dmi/id/{field}").read_text(encoding="utf-8", errors="ignore").strip()
    except OSError:
        return ""


def detect_keyboard_info() -> dict:
    """Auto-detect physical keyboard model, form-factor profile, and XKB layout."""
    device_name = ""
    layout = "cz"
    active_keymap = "Czech"
    try:
        out = subprocess.check_output(["hyprctl", "devices", "-j"], text=True, timeout=2)
        devices = json.loads(out)
        keyboards = devices.get("keyboards", [])
        ignore_tokens = (
            "virtual", "kando", "uinput", "ydotool", "power-button", "video-bus",
            "wireless-radio", "avrcp", "extra-buttons", "consumer", "sleep-button",
        )
        real_kbs = [
            k for k in keyboards
            if not any(tok in (k.get("name") or "").lower() for tok in ignore_tokens)
        ]
        pool = real_kbs or keyboards
        chosen = next((k for k in pool if k.get("main")), None)
        if chosen is None and pool:
            chosen = pool[0]
        if chosen:
            device_name = chosen.get("name", "")
            raw_layout = (chosen.get("layout") or "cz").split(",")[0].strip().lower()
            if raw_layout:
                layout = raw_layout
            active_keymap = chosen.get("active_keymap") or active_keymap
    except Exception:
        pass

    vendor = _read_dmi("sys_vendor")
    prod_version = _read_dmi("product_version")
    prod_name = _read_dmi("product_name")
    dmi_blob = f"{vendor} {prod_version} {prod_name}".lower()
    dev_low = device_name.lower()

    iso_layouts = {
        "cz", "sk", "de", "fr", "gb", "uk", "es", "it", "pt", "pl",
        "hu", "se", "no", "dk", "fi", "ch", "at", "be", "nl", "hr", "si",
    }
    is_iso = layout in iso_layouts

    profile = "tkl"
    model_label = prod_version or prod_name or device_name or "Keyboard"

    is_builtin_laptop = any(tok in dev_low for tok in ("ite-device", "at-translated-set-2", "laptop", "internal"))
    if is_builtin_laptop and any(tok in dmi_blob for tok in ("ideapad gaming", "legion", "loq", "82sb", "ideapad")):
        profile = "ideapad-gaming-3"
        model_label = prod_version or "IdeaPad Gaming 3"
    elif any(tok in dev_low for tok in ("60%", "65%", "75%", "anne", "k2", "k6", "q1", "q2", "wooting")):
        profile = "compact-75"
        model_label = device_name
    elif is_builtin_laptop:
        profile = "ideapad-gaming-3"
    elif any(tok in dev_low for tok in ("tkl", "80%", "87")):
        profile = "tkl"
        model_label = device_name
    elif device_name:
        model_label = device_name.replace("-", " ").title()

    return {
        "model": model_label,
        "device": device_name,
        "profile": profile,
        "layout": layout,
        "keymap": active_keymap,
        "isIso": is_iso,
    }


MODIFIER_ORDER = ("Super", "Ctrl", "Alt", "Shift")
MODIFIER_SET = set(MODIFIER_ORDER)

KEY_ID_MAP = {
    "; (pod esc)": "Grave",
    ",": "Comma",
    ".": "Period",
    "mouse wheel up": "MouseWheelUp",
    "mouse wheel down": "MouseWheelDown",
    "left drag": "MouseLeft",
    "right drag": "MouseRight",
    "volume up": "VolumeUp",
    "volume down": "VolumeDown",
    "audio mute": "AudioMute",
    "mic mute": "MicMute",
    "brightness up": "BrightnessUp",
    "brightness down": "BrightnessDown",
    "media play": "MediaPlay",
    "media pause": "MediaPause",
    "media stop": "MediaStop",
    "next track": "MediaNext",
    "previous track": "MediaPrev",
}

SHORT_LABEL_RULES = [
    (r"Terminal \(Kitty\)", "Kitty"),
    (r"Terminal \((\w+)\)", r"\1"),
    (r"File Manager \(Dolphin\)", "Files"),
    (r"File Manager", "Files"),
    (r"Web Browser", "Web"),
    (r"Open Obsidian", "Obsid"),
    (r"Open Equibop", "Chat"),
    (r"spot-launch|Application Launcher", "Launch"),
    (r"spot-window|Visual Window Switcher", "WinSw"),
    (r"Clipboard History", "Clip"),
    (r"Close Focused Window", "Close"),
    (r"Toggle Floating Mode", "Float"),
    (r"Pin Floating Window", "Pin"),
    (r"Toggle Pseudo-tiling", "Pseudo"),
    (r"Toggle Tiled Fullscreen", "FullT"),
    (r"Toggle Fullscreen", "Full"),
    (r"Toggle Split Direction", "Split"),
    (r"Center Floating Window", "Center"),
    (r"Cycle Windows Backward", "PrevW"),
    (r"Cycle Windows", "Cycle"),
    (r"Move Focus Left", "Foc ←"),
    (r"Move Focus Right", "Foc →"),
    (r"Move Focus Up", "Foc ↑"),
    (r"Move Focus Down", "Foc ↓"),
    (r"Move Window Left", "Mov ←"),
    (r"Move Window Right", "Mov →"),
    (r"Move Window Up", "Mov ↑"),
    (r"Move Window Down", "Mov ↓"),
    (r"Swap Window Left", "Swp ←"),
    (r"Swap Window Right", "Swp →"),
    (r"Swap Window Up", "Swp ↑"),
    (r"Swap Window Down", "Swp ↓"),
    (r"Switch to Workspace 1–5", "WS 1-5"),
    (r"Move Window to Workspace 1–5 Silently", "Sil WS"),
    (r"Move Window to Workspace 1–5", "→WS1-5"),
    (r"Next Workspace", "NextWS"),
    (r"Previous Workspace", "PrevWS"),
    (r"Toggle Magic Scratchpad", "Magic"),
    (r"Send Window to Magic Scratchpad", "→Magic"),
    (r"Toggle Terminal Scratchpad", "Term"),
    (r"Send Window to Terminal Scratchpad", "→Term"),
    (r"Lock Screen", "Lock"),
    (r"Reload Hyprland", "Reload"),
    (r"Exit Hyprland", "Exit"),
    (r"Enter Interactive Resize Mode", "Resize"),
    (r"Exit Resize Mode", "Done"),
    (r"Resize Window Wider", "+W"),
    (r"Resize Window Narrower", "-W"),
    (r"Resize Window Shorter", "-H"),
    (r"Resize Window Taller", "+H"),
    (r"Wallpaper Picker", "Walls"),
    (r"Hyprland Session Settings", "Prefs"),
    (r"YouTube Music", "Music"),
    (r"Toggle Window Group", "Group"),
    (r"Move Window Out of Group", "Ungrp"),
    (r"Next Tab in Active Group", "Tab →"),
    (r"Previous Tab in Active Group", "Tab ←"),
    (r"Interactive Region Screenshot", "Region"),
    (r"Capture Fullscreen Screenshot", "Full"),
    (r"Capture Active Window Screenshot", "Win"),
    (r"Satty Editor", "Satty"),
    (r"Keybind Reference", "Help"),
    (r"BongoCat", "Bongo"),
    (r"Notification Center", "Notif"),
    (r"Toggle Caps Lock", "Caps"),
    (r"Lock floating|Lock window", "Pin"),
    (r"Output Volume \+5%", "Vol +"),
    (r"Output Volume -5%", "Vol -"),
    (r"Audio Mute", "Mute"),
    (r"Microphone Mute", "Mic"),
    (r"Brightness \+5%", "Bri +"),
    (r"Brightness -5%", "Bri -"),
    (r"Media Play / Pause", "Play"),
    (r"Stop Media", "Stop"),
    (r"Next Media Track", "Next"),
    (r"Previous Media Track", "Prev"),
    (r"Move Window", "Drag"),
    (r"Resize Window", "Resize"),
]


def make_short_label(action: str) -> str:
    """Create a concise keycap label derived from a full action description."""
    for pat, repl in SHORT_LABEL_RULES:
        if re.search(pat, action, re.I):
            return re.sub(pat, repl, action, count=1, flags=re.I) if "\\" in repl else repl
    cleaned = re.sub(r"\([^)]*\)", "", action).strip()
    cleaned = re.sub(r"^(Open|Toggle|Switch to|Capture|Adjust|Run)\s+", "", cleaned, flags=re.I)
    words = cleaned.split()
    out = " ".join(words[:2]) if words else action
    return out[:11]


def parse_key_components(formatted_key: str, cat: str) -> tuple[list[str], list[str], str]:
    """Return canonical (mods, physical_key_ids, submap) for a formatted key string."""
    parts = [p.strip() for p in formatted_key.split(" + ") if p.strip()]
    mods_found: set[str] = set()
    triggers: list[str] = []
    for p in parts:
        if p in MODIFIER_SET:
            mods_found.add(p)
        else:
            triggers.append(p)

    mods = [m for m in MODIFIER_ORDER if m in mods_found]
    keys: list[str] = []
    for tok in triggers:
        low = tok.lower()
        if low in KEY_ID_MAP:
            keys.append(KEY_ID_MAP[low])
        elif re.match(r"^(\d)[–-](\d)$", tok):
            start_d, end_d = int(tok[0]), int(tok[2])
            for d in range(start_d, end_d + 1):
                keys.append(str(d))
        elif len(tok) == 1:
            keys.append(tok.upper())
        else:
            keys.append(tok)

    submap = "resize" if cat == "Resize Mode" else ""
    return mods, keys, submap


def deduplicate_binds(binds: list[dict]) -> list[dict]:
    """Merge duplicate (cat, key) bindings, preferring primary over auxiliary actions."""
    seen: dict[tuple[str, str], dict] = {}
    order: list[tuple[str, str]] = []
    for item in binds:
        k = (item["cat"], item["key"])
        if k not in seen:
            seen[k] = item
            order.append(k)
        elif seen[k]["aux"] and not item["aux"]:
            seen[k] = item
        elif not item["aux"] and item["action"] != seen[k]["action"]:
            seen[k] = {**seen[k], "action": f"{seen[k]['action']} / {item['action']}"}
    enriched = []
    for k in order:
        entry = seen[k]
        mods, keys, submap = parse_key_components(entry["key"], entry["cat"])
        enriched.append({
            "cat": entry["cat"],
            "key": entry["key"],
            "action": entry["action"],
            "shortLabel": make_short_label(entry["action"]),
            "mods": mods,
            "keys": keys,
            "submap": submap,
        })
    return enriched


def extract_all(hypr_dir: Path) -> dict:
    """Extract keybinds from Lua configs, .conf files, and hyprctl fallback."""
    binds: list[dict] = []
    if hypr_dir.is_dir():
        for lua_file in sorted(hypr_dir.rglob("*.lua")):
            if lua_file.name.endswith(".bak"):
                continue
            binds.extend(parse_lua_file(lua_file))
        for conf_file in sorted(hypr_dir.rglob("*.conf")):
            if conf_file.name.endswith(".bak"):
                continue
            binds.extend(parse_conf_file(conf_file))

    binds.extend(parse_hyprctl_binds())
    clean_binds = deduplicate_binds(binds)

    present_cats = {b["cat"] for b in clean_binds}
    categories = [{"name": name, "icon": icon} for name, icon in CATEGORY_META if name in present_cats]
    return {
        "keyboard": detect_keyboard_info(),
        "categories": categories,
        "binds": clean_binds,
    }


if __name__ == "__main__":
    target_dir = Path(os.path.expanduser(sys.argv[1] if len(sys.argv) > 1 else "~/.config/hypr"))
    print(json.dumps(extract_all(target_dir), ensure_ascii=False))

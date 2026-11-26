# qml-keybind-help

Standalone Hyprland keybind reference & interactive visual keyboard map built with Quickshell and Qt Quick 6.10.

## Features

- **Automatic Keybind Extraction:** Parses Hyprlua (`*.lua`, `hl.bind`, `hl.define_submap`), standard Hyprland (`*.conf`, `bind*`/`bindd`), and `hyprctl binds -j` fallback.
- **Interactive Visual Keyboard Map (`Seznam | Klávesnice`):**
  - Auto-detects connected physical keyboard model & active XKB layout via `hyprctl devices -j` + DMI (`Lenovo IdeaPad Gaming 3` w/ L-shaped ISO Enter, offset inverted-T arrows & 4-col Numpad, plus switchable `TKL 80%`, `Compact 75%`, and `CZ ISO` / `US ANSI`).
  - Layer pills (`Vše`, `Super`, `Super+Shift`, `Super+Alt`, `Super+Ctrl`, `Alt`, `Resize`) + live held-modifier detection (`LIVE`).
  - **Density Heatmap Mode:** Highlights bound vs. free keys across all modifier layers with count badges.
  - **Mouse Controls & Key Inspector:** Hover or click any key/mouse control to inspect all shortcuts on that key or spot free keys.
- **Caelestia Auto-Theme & Standalone Presets:**
  - `auto` mode follows **Caelestia Shell** (`~/.local/state/caelestia/scheme.json`, live Material 3 dark/light tonal tokens) → falls back to **Pywal** (`~/.cache/wal/colors.json`) → falls back to built-in **Catppuccin Mocha**.
  - Built-in standalone presets (no external theme engine required): `catppuccin-mocha`, `tokyo-night`, `gruvbox-dark`, `nord`, `rose-pine`, `catppuccin-latte`. Switch live from the header pill or via IPC.

## Run

```bash
quickshell -p ~/.config/qml-keybind-help

# Toggle overlay (list or last active view)
qs ipc -p ~/.config/qml-keybind-help call keybindhelp toggle

# Open directly in visual keyboard view
qs ipc -p ~/.config/qml-keybind-help call keybindhelp toggleKeyboard

# Switch theme at runtime (auto | catppuccin-mocha | tokyo-night | gruvbox-dark | nord | rose-pine | catppuccin-latte)
qs ipc -p ~/.config/qml-keybind-help call keybindhelp setTheme tokyo-night
```

## Configuration

Edit `~/.config/qml-keybind-help/config.json`:

- `keybindhelp.hyprConfigDir`: path to your Hyprland config directory (default `~/.config/hypr`)
- `appearance.fontFamily`: UI font family (default `Inter`)
- `appearance.theme`: `"auto"` or any standalone preset ID
- `paths.caelestiaScheme`: path to Caelestia `scheme.json` (default `~/.local/state/caelestia/scheme.json`)
- `paths.pywalColors`: fallback path to Pywal `colors.json`

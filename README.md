# qml-keybind-help

Standalone Hyprland keybind reference overlay built with Quickshell and Qt Quick 6.10.

## Features

- Automatically extracts keybinds from Hyprlua (`*.lua`), standard Hyprland (`*.conf` / `bindd`), and `hyprctl binds -j`
- Generates readable descriptions from inline comments, `bindd` descriptions, dispatchers, and command patterns
- Live search across key combinations, descriptions, and categories
- Keyboard navigation (`↑`/`↓`, `Tab`, `Esc`) and Pywal color palette support
- Controlled via Quickshell IPC (`keybindhelp toggle | open | close | refresh`)

## Run

```bash
quickshell -p ~/.config/qml-keybind-help
quickshell -p ~/.config/qml-keybind-help ipc call keybindhelp toggle
```

## Configuration

Edit `~/.config/qml-keybind-help/config.json`:

- `keybindhelp.hyprConfigDir`: path to your Hyprland config directory (default `~/.config/hypr`)
- `appearance.fontFamily`: UI font family
- `paths.pywalColors`: path to pywal `colors.json`

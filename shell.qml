//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded

import Quickshell
import QtQuick 6.10
import "services" as QsServices
import "modules/keybindhelp"

ShellRoot {
    id: root
    readonly property var pywal: QsServices.Pywal

    KeybindHelpWindow {}
}

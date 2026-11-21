import QtQuick 6.10
import "." as QsServices

QtObject {
    id: root
    
    property var fallback: null
    
    // Pywal color properties with defaults from fallback or dark palette
    property color background: fallback ? fallback.background : "#070605"
    property color foreground: fallback ? fallback.foreground : "#e9e5e6"
    property color cursor: fallback ? fallback.cursor : "#e9e5e6"
    
    // Individual color properties for easy access
    property color color0: fallback ? fallback.color0 : "#070605"
    property color color1: fallback ? fallback.color1 : "#DE1222"
    property color color2: fallback ? fallback.color2 : "#37B679"
    property color color3: fallback ? fallback.color3 : "#FF9F00"
    property color color4: fallback ? fallback.color4 : "#CE6649"
    property color color5: fallback ? fallback.color5 : "#9A847D"
    property color color6: fallback ? fallback.color6 : "#B39FA7"
    property color color7: fallback ? fallback.color7 : "#e9e5e6"
    property color color8: fallback ? fallback.color8 : "#a3a0a1"
    property color color9: fallback ? fallback.color9 : "#DE1222"
    property color color10: fallback ? fallback.color10 : "#37B679"
    property color color11: fallback ? fallback.color11 : "#BE5052"
    property color color12: fallback ? fallback.color12 : "#CE6649"
    property color color13: fallback ? fallback.color13 : "#9A847D"
    property color color14: fallback ? fallback.color14 : "#B39FA7"
    property color color15: fallback ? fallback.color15 : "#e9e5e6"
    
    // Semantic tokens
    readonly property color primary: color4
    readonly property color primaryContainer: Qt.rgba(color4.r, color4.g, color4.b, 0.2)
    readonly property color onPrimary: foreground
    
    readonly property color secondary: color5
    readonly property color secondaryContainer: Qt.rgba(color5.r, color5.g, color5.b, 0.2)
    
    readonly property color tertiary: color6
    readonly property color tertiaryContainer: Qt.rgba(color6.r, color6.g, color6.b, 0.2)
    
    readonly property color surface: Qt.lighter(background, 1.15)
    readonly property color surfaceDim: Qt.darker(background, 1.15)
    readonly property color surfaceBright: Qt.lighter(background, 1.50)
    readonly property color surfaceContainerLow: Qt.lighter(background, 1.25)
    readonly property color surfaceContainer: Qt.lighter(background, 1.45)
    readonly property color surfaceContainerHigh: Qt.lighter(background, 1.75)
    readonly property color surfaceContainerHighest: Qt.lighter(background, 2.10)
    readonly property color onSurface: foreground
    readonly property color onSurfaceVariant: color8
    readonly property color onSurfaceMuted: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.68)

    readonly property color glassLow: surfaceContainerLow
    readonly property color glassHigh: surfaceContainerHigh
    readonly property color glassHighest: surfaceContainerHighest
    readonly property color glassBorder: outlineVariant
    readonly property color glassBorderStrong: Qt.rgba(primary.r, primary.g, primary.b, 0.28)
    
    readonly property color outline: color8
    readonly property color outlineVariant: Qt.rgba(color8.r, color8.g, color8.b, 0.5)
    
    readonly property color success: color2
    readonly property color onSuccess: background
    readonly property color warning: color3
    readonly property color onWarning: background
    readonly property color error: color1
    readonly property color onError: foreground
    readonly property color info: color4
    
    readonly property color stateLayerLight: Qt.rgba(foreground.r, foreground.g, foreground.b, 1)
    readonly property color stateLayerDark: Qt.rgba(background.r, background.g, background.b, 1)
    
    readonly property color inverseSurface: foreground
    readonly property color inverseOnSurface: background
    readonly property color inversePrimary: Qt.lighter(primary, 1.5)
    
    readonly property color scrim: Qt.rgba(0, 0, 0, 0.5)
    readonly property color shadow: Qt.rgba(0, 0, 0, 0.3)
    
    function loadColors(text: string): void {
        try {
            const data = JSON.parse(text);
            if (data.special) {
                if (data.special.background) root.background = data.special.background;
                if (data.special.foreground) root.foreground = data.special.foreground;
                if (data.special.cursor) root.cursor = data.special.cursor;
            }
            if (data.colors) {
                if (data.colors.color0) root.color0 = data.colors.color0;
                if (data.colors.color1) root.color1 = data.colors.color1;
                if (data.colors.color2) root.color2 = data.colors.color2;
                if (data.colors.color3) root.color3 = data.colors.color3;
                if (data.colors.color4) root.color4 = data.colors.color4;
                if (data.colors.color5) root.color5 = data.colors.color5;
                if (data.colors.color6) root.color6 = data.colors.color6;
                if (data.colors.color7) root.color7 = data.colors.color7;
                if (data.colors.color8) root.color8 = data.colors.color8;
                if (data.colors.color9) root.color9 = data.colors.color9;
                if (data.colors.color10) root.color10 = data.colors.color10;
                if (data.colors.color11) root.color11 = data.colors.color11;
                if (data.colors.color12) root.color12 = data.colors.color12;
                if (data.colors.color13) root.color13 = data.colors.color13;
                if (data.colors.color14) root.color14 = data.colors.color14;
                if (data.colors.color15) root.color15 = data.colors.color15;
            }
        } catch (e) {
            QsServices.Logger.warn("PywalTheme", `Failed to parse subtheme colors: ${e?.message ?? e}`)
        }
    }
}

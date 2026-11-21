pragma Singleton

import Quickshell
import QtQuick
import "." as QsServices

// Centralized UI state management
Singleton {
    id: root
    
    // Panel visibility states
    property bool controlCenterOpen: false
    property bool launcherOpen: false
    property bool dashboardOpen: false
    property bool volumePopupOpen: false
    property bool sidebarOpen: false
    
    // Active popup tracking (only one popup at a time)
    property string activePopup: ""  // "volume", "network", "bluetooth", "brightness", "media"
    
    // User preferences
    property bool dndMode: false
    property bool idleInhibited: false
    property string powerProfile: "balanced"  // "performance", "balanced", "power-saver"
    
    // Notification state
    property int unreadNotifications: 0
    
    // Media state
    property bool mediaPlaying: false
    property string activeMediaPlayer: ""
    
    // System state
    property bool onBattery: false
    property int batteryPercentage: 100
    property bool lowBattery: batteryPercentage < 20
    
    // Startup animation guard: animations are disabled during initial startup/load
    // and automatically enabled shortly after initial rendering is complete.
    property bool startupComplete: false
    property bool animationsEnabled: false

    Timer {
        id: startupTimer
        interval: 350
        running: true
        repeat: false
        onTriggered: {
            root.startupComplete = true
            QsServices.Logger.info("UIState", "Startup complete - surfaces revealed")
            animEnableTimer.restart()
        }
    }

    Timer {
        id: animEnableTimer
        interval: 100
        running: false
        repeat: false
        onTriggered: {
            root.animationsEnabled = true
            QsServices.Logger.info("UIState", "Animations enabled")
        }
    }
    
    // Persist important state across reloads
    PersistentProperties {
        id: persist
        property alias dndMode: root.dndMode
        property alias powerProfile: root.powerProfile
        property alias idleInhibited: root.idleInhibited
    }
    
    // Helper functions
    function closeAllPopups() {
        activePopup = ""
    }
    
    function openPopup(popupName) {
        if (activePopup === popupName) {
            activePopup = ""  // Toggle off
        } else {
            activePopup = popupName
        }
    }
    
    function closeAllPanels() {
        controlCenterOpen = false
        launcherOpen = false
        dashboardOpen = false
    }
    
    function toggleControlCenter() {
        controlCenterOpen = !controlCenterOpen
        if (controlCenterOpen) {
            // Close other panels
            launcherOpen = false
            dashboardOpen = false
            closeAllPopups()
        }
    }
    
    Component.onCompleted: {
        QsServices.Logger.debug("UIState", "Service initialized")
    }
}

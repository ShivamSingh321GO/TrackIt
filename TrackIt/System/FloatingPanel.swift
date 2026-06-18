//
//  FloatingPanel.swift
//  TrackIt
//
//  A custom NSPanel subclass that floats above all windows (including fullscreen spaces),
//  is draggable by its background, and does NOT steal focus from the user's active app.
//

import AppKit

/// A non-activating floating panel that:
/// - Stays on top of every window, including fullscreen apps
/// - Does NOT steal keyboard focus when clicked (the user keeps typing in their editor)
/// - Is freely draggable by clicking and dragging anywhere on its background
/// - Appears on every macOS Space
class FloatingPanel: NSPanel {
    
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [
                .titled,             // Needed for traffic-light buttons
                .closable,
                .miniaturizable,
                .nonactivatingPanel  // KEY: clicking the panel doesn't activate the app / steal focus
            ],
            backing: .buffered,
            defer: false
        )
        
        // Float above everything, including fullscreen apps
        self.level = .screenSaver
        
        // Appear on every Space (including fullscreen ones)
        self.collectionBehavior = [
            .canJoinAllSpaces,      // Show on every desktop Space
            .fullScreenAuxiliary,   // Allowed to overlay fullscreen apps
            .stationary,            // Stay put when Spaces switch
            .ignoresCycle           // Don't appear in Cmd+Tab / Mission Control
        ]
        
        // Allow the panel to receive key events even though it's non-activating
        // (needed for the text field / timer input)
        self.becomesKeyOnlyIfNeeded = true
        
        // Make the entire window background draggable
        self.isMovableByWindowBackground = true
        
        // Visual polish
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        
        // Don't destroy when closed, allow re-show
        self.isReleasedWhenClosed = false
        
        // Float above other app windows even when not focused
        self.hidesOnDeactivate = false
    }
    
    // MARK: - Key Event Overrides
    
    /// Allow the panel to become the key window (for text field input)
    /// only when the user explicitly clicks into an editable field.
    override var canBecomeKey: Bool { true }
    
    /// Prevent the panel from ever becoming the "main" window,
    /// which would steal activation from the user's real working app.
    override var canBecomeMain: Bool { false }
    
    /// Swallow double-click on the title bar area so macOS doesn't
    /// try to zoom/maximize the panel.
    override func mouseDown(with event: NSEvent) {
        if event.clickCount >= 2 {
            return
        }
        super.mouseDown(with: event)
    }
    
    /// Intercept the green zoom button click.
    /// Instead of the default macOS zoom behavior, post a notification
    /// so ContentView can transition to the workspace view.
    override func zoom(_ sender: Any?) {
        NotificationCenter.default.post(name: FloatingPanel.zoomRequestedNotification, object: self)
    }
    
    /// Notification posted when the user clicks the green zoom button.
    static let zoomRequestedNotification = Notification.Name("FloatingPanelZoomRequested")
}

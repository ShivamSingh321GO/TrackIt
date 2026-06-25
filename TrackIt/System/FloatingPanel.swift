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
                .borderless,
                .resizable,
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
    
    /// Allow the panel to become the main window in workspace mode
    /// so it can enter native macOS full screen.
    override var canBecomeMain: Bool {
        return self.styleMask.contains(.titled)
    }
    
    /// Swallow double-click on the title bar area so macOS doesn't
    /// try to zoom/maximize the panel.
    override func mouseDown(with event: NSEvent) {
        if event.clickCount >= 2 {
            return
        }
        super.mouseDown(with: event)
    }
    
    /// Override zoom: in workspace mode trigger native full screen,
    /// in timer mode post notification to transition to workspace.
    override func zoom(_ sender: Any?) {
        // If the window is small (timer mode), transition to workspace instead of full screening
        if self.frame.width <= 250 {
            NotificationCenter.default.post(name: FloatingPanel.zoomRequestedNotification, object: self)
        } else {
            self.toggleFullScreen(sender)
        }
    }
    
    /// Notification posted when the user clicks the green zoom button in timer mode.
    static let zoomRequestedNotification = Notification.Name("FloatingPanelZoomRequested")
}

//
//  TrackItApp.swift
//  TrackIt
//
//  Created by shivam kumar singh on 6/3/26.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var floatingPanel: FloatingPanel?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide the default SwiftUI WindowGroup window — we'll host our own panel
        DispatchQueue.main.async {
            // Close any auto-created SwiftUI windows
            for window in NSApp.windows where !(window is FloatingPanel) {
                window.close()
            }
            
            self.createFloatingPanel()
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if let panel = self.floatingPanel {
            panel.orderFrontRegardless()
        } else {
            self.createFloatingPanel()
        }
        return true
    }
    
    private func createFloatingPanel() {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 210, height: 120)
        )
        
        // Host the SwiftUI ContentView inside this panel
        let contentView = ContentView()
        let hostingView = NSHostingView(rootView: contentView)
        panel.contentView = hostingView
        
        // Position in the top-right corner of the screen
        if let screen = NSScreen.main {
            let visibleFrame = screen.visibleFrame
            let padding: CGFloat = 20
            let origin = NSPoint(
                x: visibleFrame.maxX - 210 - padding,
                y: visibleFrame.maxY - 120 - padding
            )
            panel.setFrameOrigin(origin)
        }
        
        // Show the panel without activating the app (non-intrusive)
        panel.orderFrontRegardless()
        
        self.floatingPanel = panel
    }
}

@main
struct TrackItApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Empty Settings scene — the real UI is hosted by AppDelegate's FloatingPanel.
        // We use Settings instead of WindowGroup to prevent SwiftUI from auto-creating
        // a standard NSWindow that would compete with our floating panel.
        Settings {
            EmptyView()
        }
    }
}

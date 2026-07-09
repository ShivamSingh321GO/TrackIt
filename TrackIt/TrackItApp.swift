//
//  TrackItApp.swift
//  TrackIt
//
//  Created by shivam kumar singh on 6/3/26.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuItemValidation {
    var floatingPanel: FloatingPanel?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide the default SwiftUI WindowGroup window — we'll host our own panel
        DispatchQueue.main.async {
            // Close any auto-created SwiftUI windows
            for window in NSApp.windows where !(window is FloatingPanel) {
                window.close()
            }
            
            self.configureMainMenu()
            
            if !UserDefaults.standard.bool(forKey: "SF_HasSeenTutorial") {
                TutorialWindowManager.shared.showTutorial()
                NotificationCenter.default.addObserver(forName: Notification.Name("TutorialDidFinish"), object: nil, queue: .main) { _ in
                    if self.floatingPanel == nil {
                        self.createFloatingPanel()
                    }
                }
            } else {
                self.createFloatingPanel()
            }
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !UserDefaults.standard.bool(forKey: "SF_HasSeenTutorial") {
            TutorialWindowManager.shared.showTutorial()
            return true
        }
        
        if let panel = self.floatingPanel {
            if panel.isMiniaturized {
                panel.deminiaturize(nil)
                return false // Prevents AppKit from doing a default restore which interrupts the animation
            } else {
                panel.orderFrontRegardless()
            }
        } else {
            self.createFloatingPanel()
        }
        return true
    }
    
    func createFloatingPanel() {
        let frameSize = NSSize(width: 210, height: 120)
        let styleMask: NSWindow.StyleMask = [
            .titled,
            .closable,
            .miniaturizable,
            .nonactivatingPanel
        ]
        let contentRect = NSWindow.contentRect(forFrameRect: NSRect(origin: .zero, size: frameSize), styleMask: styleMask)
        
        let panel = FloatingPanel(
            contentRect: contentRect
        )
        
        // Lock initial constraints to normal size to prevent any layout stretching on launch
        panel.minSize = frameSize
        panel.maxSize = frameSize
        
        // Host the SwiftUI ContentView inside this panel
        let contentView = ContentView()
        let hostingView = NSHostingView(rootView: contentView)
        panel.contentView = hostingView
        
        // Position in the top-right corner of the screen
        if let screen = NSScreen.main {
            let visibleFrame = screen.visibleFrame
            let padding: CGFloat = 20
            let origin = NSPoint(
                x: visibleFrame.maxX - frameSize.width - padding,
                y: visibleFrame.maxY - frameSize.height - padding
            )
            panel.setFrameOrigin(origin)
        }
        
        // Show the panel without activating the app (non-intrusive)
        panel.orderFrontRegardless()
        
        self.floatingPanel = panel
        self.configureMainMenu()
    }
    
    func configureMainMenu() {
        if let mainMenu = NSApp.mainMenu {
            for item in mainMenu.items {
                if let submenu = item.submenu {
                    submenu.delegate = self
                    updateAppSettingsMenu(submenu)
                }
            }
        }
    }
    
    func updateAppSettingsMenu(_ menu: NSMenu) {
        for item in menu.items {
            if item.keyEquivalent == "," || item.title.contains("Settings") || item.action == Selector(("showSettingsWindow:")) {
                item.target = StatusItemTarget.shared
                item.action = #selector(StatusItemTarget.openSettings)
                item.isEnabled = true
            }
            if item.action == #selector(NSApplication.terminate(_:)) || item.title.contains("Quit") {
                item.isEnabled = true
            }
            if item.action == #selector(NSApplication.hide(_:)) || item.action == #selector(NSApplication.hideOtherApplications(_:)) || item.title.contains("Hide") {
                item.isEnabled = true
            }
            if item.action == #selector(NSApplication.orderFrontStandardAboutPanel(_:)) || item.title.contains("About") {
                item.isEnabled = true
            }
        }
    }
    
    @objc func showSettingsWindow(_ sender: Any?) {
        StatusItemTarget.shared.openSettings()
    }
    
    @objc func validateMenuItem(_ item: NSMenuItem) -> Bool {
        return true
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        updateAppSettingsMenu(menu)
    }
}

@main
struct TrackItApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Empty Settings scene — the real UI is hosted by AppDelegate's FloatingPanel / SettingsWindowManager.
        // We use Settings instead of WindowGroup to prevent SwiftUI from auto-creating
        // a standard NSWindow that would compete with our floating panel.
        Settings {
            EmptyView()
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    StatusItemTarget.shared.openSettings()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}

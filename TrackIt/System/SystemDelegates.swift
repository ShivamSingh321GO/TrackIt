import SwiftUI
import AppKit
import UserNotifications

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    override init() {
        super.init()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show banner and play sound even in foreground
        completionHandler([.banner, .sound])
    }
}

class StatusItemTarget: NSObject {
    static let shared = StatusItemTarget()
    
    weak var manager: SessionFlowManager? = nil
    
    @objc func showAppWindow() {
        // Bring the floating panel to front without stealing focus from the user's active app
        for window in NSApp.windows {
            if window is FloatingPanel {
                window.orderFrontRegardless()
            } else {
                window.makeKeyAndOrderFront(nil)
            }
        }
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func openSettings() {
        guard let manager = manager else { return }
        DispatchQueue.main.async {
            SettingsWindowManager.shared.showSettings(manager: manager)
        }
    }
    
    @objc func openTutorial() {
        DispatchQueue.main.async {
            TutorialWindowManager.shared.showTutorial()
        }
    }
    
    @objc func toggleTimer() {
        guard let manager = manager else { return }
        if manager.isRunning {
            manager.pauseTimer()
        } else {
            manager.startTimer()
        }
    }
    
    @objc func resetTimer() {
        guard let manager = manager else { return }
        let duration = manager.timerDuration
        manager.resetTimer()
        manager.timerDuration = duration
        manager.startTimer()
    }
    
    @objc func resetAndPauseTimer() {
        guard let manager = manager else { return }
        let duration = manager.timerDuration
        manager.resetTimer()
        manager.timerDuration = duration
    }
}

class SettingsWindowManager: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowManager()
    private var window: NSWindow?
    
    func showSettings(manager: SessionFlowManager) {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let settingsView = SettingsSheet(manager: manager)
        let hostingView = NSHostingView(rootView: settingsView)
        
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 260),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        newWindow.title = "Settings"
        newWindow.contentView = hostingView
        newWindow.center()
        newWindow.isReleasedWhenClosed = false
        newWindow.delegate = self
        newWindow.level = NSWindow.Level(rawValue: Int(NSWindow.Level.screenSaver.rawValue) + 1)
        
        self.window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func closeSettings() {
        DispatchQueue.main.async { [weak self] in
            self?.window?.close()
            self?.window = nil
        }
    }
    
    func windowWillClose(_ notification: Notification) {
        self.window = nil
    }
}

class SaveSheetWindowManager: NSObject, NSWindowDelegate {
    static let shared = SaveSheetWindowManager()
    private var window: NSWindow?
    weak var onDismissManager: SessionFlowManager?
    
    func showSaveSheet(manager: SessionFlowManager, duration: TimeInterval) {
        // Close existing window if any
        if let window = window {
            window.close()
            self.window = nil
        }
        
        onDismissManager = manager
        
        let saveView = SessionSaveSheet(manager: manager, duration: duration)
        let hostingView = NSHostingView(rootView: saveView)

        
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 600),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        newWindow.title = "Complete Session"
        newWindow.contentView = hostingView
        newWindow.center()
        newWindow.isReleasedWhenClosed = false
        newWindow.delegate = self
        newWindow.titleVisibility = .hidden
        newWindow.titlebarAppearsTransparent = true
        newWindow.backgroundColor = NSColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 1.0)
        newWindow.level = NSWindow.Level(rawValue: Int(NSWindow.Level.screenSaver.rawValue) + 1)
        
        self.window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func closeSaveSheet() {
        DispatchQueue.main.async { [weak self] in
            self?.window?.close()
            self?.window = nil
            self?.onDismissManager?.showSaveSheet = false
        }
    }
    
    func windowWillClose(_ notification: Notification) {
        self.window = nil
        DispatchQueue.main.async { [weak self] in
            self?.onDismissManager?.showSaveSheet = false
        }
    }
}

class TutorialWindowManager: NSObject, NSWindowDelegate {
    static let shared = TutorialWindowManager()
    private var window: NSWindow?
    
    func showTutorial() {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let tutorialView = TutorialSheet()
        let hostingView = NSHostingView(rootView: tutorialView)
        
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 650),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        newWindow.title = "Tutorial"
        newWindow.contentView = hostingView
        newWindow.center()
        newWindow.isReleasedWhenClosed = false
        newWindow.delegate = self
        newWindow.titleVisibility = .hidden
        newWindow.titlebarAppearsTransparent = true
        newWindow.backgroundColor = NSColor.windowBackgroundColor
        newWindow.level = NSWindow.Level(rawValue: Int(NSWindow.Level.screenSaver.rawValue) + 1)
        
        self.window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func closeTutorial() {
        DispatchQueue.main.async { [weak self] in
            self?.window?.close()
            self?.window = nil
            UserDefaults.standard.set(true, forKey: "SF_HasSeenTutorial")
            NotificationCenter.default.post(name: Notification.Name("TutorialDidFinish"), object: nil)
        }
    }
    
    func windowWillClose(_ notification: Notification) {
        self.window = nil
        UserDefaults.standard.set(true, forKey: "SF_HasSeenTutorial")
        NotificationCenter.default.post(name: Notification.Name("TutorialDidFinish"), object: nil)
    }
}

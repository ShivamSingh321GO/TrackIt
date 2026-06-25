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
        
        let styleMask: NSWindow.StyleMask = manager.appTheme == "Glass" ? [.titled, .closable, .miniaturizable, .fullSizeContentView] : [.titled, .closable, .miniaturizable]
        
        let standardFrame = NSWindow.frameRect(
            forContentRect: NSRect(x: 0, y: 0, width: 480, height: 260),
            styleMask: [.titled, .closable, .miniaturizable]
        )
        let contentHeight: CGFloat = manager.appTheme == "Glass" ? standardFrame.height : 260
        
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: contentHeight),
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        newWindow.title = "Settings"
        newWindow.contentView = hostingView
        
        // Position on the same screen/Space as the active FloatingPanel timer
        if let timerWindow = NSApp.windows.first(where: { $0 is FloatingPanel }),
           let screen = timerWindow.screen {
            let screenFrame = screen.visibleFrame
            let windowSize = newWindow.frame.size
            let origin = NSPoint(
                x: screenFrame.midX - windowSize.width / 2,
                y: screenFrame.midY - windowSize.height / 2
            )
            newWindow.setFrameOrigin(origin)
        } else {
            newWindow.center()
        }
        
        newWindow.isReleasedWhenClosed = false
        newWindow.delegate = self
        newWindow.level = NSWindow.Level(rawValue: Int(NSWindow.Level.screenSaver.rawValue) + 1)
        newWindow.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary
        ]
        
        newWindow.isMovableByWindowBackground = true
        
        // 1. Set appearance
        if manager.appTheme == "Dark" {
            newWindow.appearance = NSAppearance(named: .darkAqua)
        } else if manager.appTheme == "Light" {
            newWindow.appearance = NSAppearance(named: .aqua)
        } else {
            newWindow.appearance = nil
        }
        
        // 2. Set title bar transparency and visibility
        if manager.appTheme == "Glass" {
            newWindow.titlebarAppearsTransparent = true
            newWindow.titleVisibility = .hidden
        } else {
            newWindow.titlebarAppearsTransparent = false
            newWindow.titleVisibility = .hidden
        }
        
        // 3. Set transparency properties AFTER appearance and style mask
        newWindow.backgroundColor = .clear
        newWindow.isOpaque = false
        newWindow.invalidateShadow()
        
        self.window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func updateTheme(_ theme: String) {
        guard let window = window else { return }
        
        let standardFrame = NSWindow.frameRect(
            forContentRect: NSRect(x: 0, y: 0, width: 480, height: 260),
            styleMask: [.titled, .closable, .miniaturizable]
        )
        
        // 1. Update style mask first
        let newMask: NSWindow.StyleMask = theme == "Glass" ? [.titled, .closable, .miniaturizable, .fullSizeContentView] : [.titled, .closable, .miniaturizable]
        if window.styleMask != newMask {
            window.styleMask = newMask
        }
        
        // 2. Set appearance
        if theme == "Dark" {
            window.appearance = NSAppearance(named: .darkAqua)
        } else if theme == "Light" {
            window.appearance = NSAppearance(named: .aqua)
        } else {
            window.appearance = nil
        }
        
        // 3. Configure title bar
        if theme == "Glass" {
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
        } else {
            window.titlebarAppearsTransparent = false
            window.titleVisibility = .hidden
        }
        
        // 4. Force transparency and clear background AFTER style mask and appearance are updated
        window.backgroundColor = .clear
        window.isOpaque = false
        window.invalidateShadow()
        
        // 5. Adjust height and layout
        let targetHeight = theme == "Glass" ? standardFrame.height : 260
        window.setContentSize(NSSize(width: 480, height: targetHeight))
        
        window.contentView?.needsLayout = true
        window.contentView?.needsDisplay = true
        window.contentView?.layoutSubtreeIfNeeded()
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
            if let parent = window.sheetParent {
                parent.endSheet(window)
            } else {
                window.close()
            }
            self.window = nil
        }
        
        onDismissManager = manager
        
        let saveView = SessionSaveSheet(manager: manager, duration: duration)
        let hostingView = NSHostingView(rootView: saveView)

        
        let styleMask: NSWindow.StyleMask = manager.appTheme == "Glass" ? [.titled, .closable, .fullSizeContentView] : [.titled, .closable]
        
        let standardFrame = NSWindow.frameRect(
            forContentRect: NSRect(x: 0, y: 0, width: 540, height: 600),
            styleMask: [.titled, .closable]
        )
        let contentHeight: CGFloat = manager.appTheme == "Glass" ? standardFrame.height : 600
        
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: contentHeight),
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        newWindow.title = "Complete Session"
        newWindow.contentView = hostingView
        
        // Position on the same screen/Space as the active FloatingPanel timer
        if let timerWindow = NSApp.windows.first(where: { $0 is FloatingPanel }),
           let screen = timerWindow.screen {
            let screenFrame = screen.visibleFrame
            let windowSize = newWindow.frame.size
            let origin = NSPoint(
                x: screenFrame.midX - windowSize.width / 2,
                y: screenFrame.midY - windowSize.height / 2
            )
            newWindow.setFrameOrigin(origin)
        } else {
            newWindow.center()
        }
        
        newWindow.isReleasedWhenClosed = false
        newWindow.delegate = self
        newWindow.level = NSWindow.Level(rawValue: Int(NSWindow.Level.screenSaver.rawValue) + 1)
        newWindow.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary
        ]
        
        newWindow.isMovableByWindowBackground = true
        
        // 1. Set appearance
        if manager.appTheme == "Dark" {
            newWindow.appearance = NSAppearance(named: .darkAqua)
        } else if manager.appTheme == "Light" {
            newWindow.appearance = NSAppearance(named: .aqua)
        } else {
            newWindow.appearance = nil
        }
        
        // 2. Set title bar transparency and visibility
        if manager.appTheme == "Glass" {
            newWindow.titlebarAppearsTransparent = true
            newWindow.titleVisibility = .hidden
        } else {
            newWindow.titlebarAppearsTransparent = false
            newWindow.titleVisibility = .hidden
        }
        
        // 3. Set transparency properties AFTER appearance and style mask
        newWindow.backgroundColor = .clear
        newWindow.isOpaque = false
        newWindow.invalidateShadow()
        
        self.window = newWindow
        
        // Present as a standalone window so it is draggable on screen
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func updateTheme(_ theme: String) {
        guard let window = window else { return }
        
        let standardFrame = NSWindow.frameRect(
            forContentRect: NSRect(x: 0, y: 0, width: 540, height: 600),
            styleMask: [.titled, .closable]
        )
        
        // 1. Update style mask first
        let newMask: NSWindow.StyleMask = theme == "Glass" ? [.titled, .closable, .fullSizeContentView] : [.titled, .closable]
        if window.styleMask != newMask {
            window.styleMask = newMask
        }
        
        // 2. Set appearance
        if theme == "Dark" {
            window.appearance = NSAppearance(named: .darkAqua)
        } else if theme == "Light" {
            window.appearance = NSAppearance(named: .aqua)
        } else {
            window.appearance = nil
        }
        
        // 3. Configure title bar
        if theme == "Glass" {
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
        } else {
            window.titlebarAppearsTransparent = false
            window.titleVisibility = .hidden
        }
        
        // 4. Configure transparency properties AFTER style mask and appearance are updated
        window.backgroundColor = .clear
        window.isOpaque = false
        window.invalidateShadow()
        
        // 5. Adjust height and layout
        let targetHeight = theme == "Glass" ? standardFrame.height : 600
        window.setContentSize(NSSize(width: 540, height: targetHeight))
        
        window.contentView?.needsLayout = true
        window.contentView?.needsDisplay = true
        window.contentView?.layoutSubtreeIfNeeded()
    }
    
    func closeSaveSheet() {
        DispatchQueue.main.async { [weak self] in
            if let window = self?.window {
                if let parent = window.sheetParent {
                    parent.endSheet(window)
                }
                window.close()
            }
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
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        newWindow.title = "Tutorial"
        newWindow.contentView = hostingView
        
        // Position on the same screen/Space as the active FloatingPanel timer
        if let timerWindow = NSApp.windows.first(where: { $0 is FloatingPanel }),
           let screen = timerWindow.screen {
            let screenFrame = screen.visibleFrame
            let windowSize = newWindow.frame.size
            let origin = NSPoint(
                x: screenFrame.midX - windowSize.width / 2,
                y: screenFrame.midY - windowSize.height / 2
            )
            newWindow.setFrameOrigin(origin)
        } else {
            newWindow.center()
        }
        
        newWindow.isReleasedWhenClosed = false
        newWindow.delegate = self
        newWindow.isMovableByWindowBackground = true
        
        let savedTheme = UserDefaults.standard.string(forKey: "SF_AppTheme") ?? "Glass"
        
        // 1. Set appearance first
        if savedTheme == "Dark" {
            newWindow.appearance = NSAppearance(named: .darkAqua)
        } else if savedTheme == "Light" {
            newWindow.appearance = NSAppearance(named: .aqua)
        } else {
            newWindow.appearance = nil
        }
        
        // 2. Set title bar transparency and visibility
        newWindow.titleVisibility = .hidden
        newWindow.titlebarAppearsTransparent = true
        
        // 3. Set transparency properties AFTER appearance and style mask
        newWindow.backgroundColor = .clear
        newWindow.isOpaque = false
        newWindow.invalidateShadow()
        
        newWindow.level = NSWindow.Level(rawValue: Int(NSWindow.Level.screenSaver.rawValue) + 1)
        newWindow.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary
        ]
        
        self.window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func updateTheme(_ theme: String) {
        guard let window = window else { return }
        
        // 1. Set appearance first
        if theme == "Dark" {
            window.appearance = NSAppearance(named: .darkAqua)
        } else if theme == "Light" {
            window.appearance = NSAppearance(named: .aqua)
        } else {
            window.appearance = nil
        }
        
        // 2. Configure transparency properties AFTER appearance is updated
        window.backgroundColor = .clear
        window.isOpaque = false
        window.invalidateShadow()
        
        window.contentView?.needsLayout = true
        window.contentView?.needsDisplay = true
        window.contentView?.layoutSubtreeIfNeeded()
    }
    
    func closeTutorial() {
        UserDefaults.standard.set(true, forKey: "SF_HasSeenTutorial")
        NotificationCenter.default.post(name: Notification.Name("TutorialDidFinish"), object: nil)
        
        DispatchQueue.main.async { [weak self] in
            self?.window?.close()
            self?.window = nil
        }
    }
    
    func windowWillClose(_ notification: Notification) {
        UserDefaults.standard.set(true, forKey: "SF_HasSeenTutorial")
        NotificationCenter.default.post(name: Notification.Name("TutorialDidFinish"), object: nil)
        self.window = nil
    }
}

//
//  ContentView.swift
//  TrackIt
//
//  Created by Antigravity on 6/3/26.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @State private var manager = SessionFlowManager()
    @Environment(\.colorScheme) var colorScheme
    
    var isDark: Bool {
        if manager.appTheme == "Dark" {
            return true
        } else if manager.appTheme == "Light" {
            return false
        } else {
            return colorScheme == .dark
        }
    }
    
    @State private var isPlayHovered = false
    @State private var isStopHovered = false
    @State private var isResetHovered = false
    @State private var isNotesHovered = false
    @State private var isWorkspaceHovered = false
    @State private var isTrafficLightHovered = false
    @State private var showNotesPopover = false
    
    @State private var appWindow: NSWindow? = nil
    @State private var resizeWorkItem: DispatchWorkItem? = nil
    @State private var isFullScreen = false
    
    @State private var liquidAnim = false
    
    private var activeProjectColor: Color {
        if let activeId = manager.activeSessionId,
           let session = manager.sessions.first(where: { $0.id == activeId }),
           let projId = session.projectRef,
           let proj = manager.projects.first(where: { $0.id == projId }) {
            return Color(hex: proj.colorHex)
        }
        return .accentColor
    }
    
    @ViewBuilder
    private var liquidGlowView: some View {
        GeometryReader { geo in
            ZStack {
                (isDark ? Color(red: 0.05, green: 0.05, blue: 0.07) : Color(white: 0.94))
                
                Circle()
                    .fill(activeProjectColor.opacity(isDark ? 0.35 : 0.25))
                    .frame(width: geo.size.width * 1.1, height: geo.size.width * 1.1)
                    .blur(radius: 25)
                    .offset(
                        x: liquidAnim ? -geo.size.width * 0.12 : geo.size.width * 0.12,
                        y: liquidAnim ? geo.size.height * 0.08 : -geo.size.height * 0.08
                    )
                
                Circle()
                    .fill(Color.purple.opacity(isDark ? 0.22 : 0.15))
                    .frame(width: geo.size.width * 0.9, height: geo.size.width * 0.9)
                    .blur(radius: 30)
                    .offset(
                        x: liquidAnim ? geo.size.width * 0.18 : -geo.size.width * 0.18,
                        y: liquidAnim ? -geo.size.height * 0.12 : geo.size.height * 0.12
                    )
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 7.0).repeatForever(autoreverses: true)) {
                    liquidAnim.toggle()
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            if manager.appTheme == "Glass" {
                ZStack {
                    if manager.currentView == .timer {
                        liquidGlowView
                    }
                    
                    VisualEffectView(
                        material: isDark ? .hudWindow : .sidebar,
                        blendingMode: isFullScreen ? .withinWindow : .behindWindow
                    )
                    
                    if manager.currentView == .timer {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(isDark ? 0.03 : 0.08),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(isDark ? 0.15 : 0.4),
                                        Color.white.opacity(isDark ? 0.05 : 0.1),
                                        Color.black.opacity(isDark ? 0.15 : 0.05),
                                        Color.white.opacity(isDark ? 0.1 : 0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: manager.currentView == .timer ? 16 : 0))
            } else {
                if manager.currentView == .workspace {
                    DragBackground(color: isDark ? NSColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 1.0) : NSColor.white)
                } else {
                    ZStack {
                        DragBackground(color: isDark ? NSColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 1.0) : NSColor.white)
                        
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.12),
                                lineWidth: 1
                            )
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            
            Group {
                if manager.currentView == .timer {
                    timerView
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                } else {
                    WorkspaceView(manager: manager)
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(manager.appTheme == "Dark" ? .dark : (manager.appTheme == "Light" ? .light : nil))
        .onChange(of: manager.showSaveSheet) { oldValue, newValue in
            if newValue {
                SaveSheetWindowManager.shared.showSaveSheet(manager: manager, duration: manager.timeElapsed)
            } else {
                SaveSheetWindowManager.shared.closeSaveSheet()
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: manager.currentView)
        .background(
            WindowAccessor { window in
                if self.appWindow == nil {
                    self.appWindow = window
                    let managerRef = self.manager
                    
                    // Configure FloatingPanel properties
                    configureTitlebar(for: window, currentView: managerRef.currentView)
                    
                    // The FloatingPanel already handles: level, collectionBehavior,
                    // isMovableByWindowBackground, hidesOnDeactivate, non-activating style.
                    // We just need to keep titlebar style synchronized.
                    NotificationCenter.default.addObserver(
                        forName: NSWindow.didBecomeKeyNotification,
                        object: window,
                        queue: .main
                    ) { _ in
                        configureTitlebar(for: window, currentView: self.manager.currentView)
                    }
                    NotificationCenter.default.addObserver(
                        forName: NSWindow.didResignKeyNotification,
                        object: window,
                        queue: .main
                    ) { _ in
                        configureTitlebar(for: window, currentView: self.manager.currentView)
                    }
                    // NOTE: Do NOT observe didResizeNotification here.
                    // configureTitlebar modifies styleMask, which triggers another
                    // resize/constraint pass and causes a re-entrancy crash when
                    // dragging the window.
                    
                    let transitionHandler: (Notification) -> Void = { _ in
                        // Use the local 'window' constant instead of 'self.appWindow' 
                        // to avoid SwiftUI struct state capture bugs in escaping closures.
                        guard self.manager.currentView != .workspace else { return }
                        // Expand to workspace size safely BEFORE state changes
                        window.styleMask.insert(.resizable)
                        let workspaceSize = NSSize(width: 850, height: 550)
                        window.minSize = workspaceSize
                        window.maxSize = NSSize(width: 10000, height: 10000)
                        
                        let currentFrame = window.frame
                        let newWidth = max(currentFrame.width, workspaceSize.width)
                        let newHeight = max(currentFrame.height, workspaceSize.height)
                        let newFrame = NSRect(
                            x: currentFrame.origin.x - (newWidth - currentFrame.width),
                            y: currentFrame.origin.y - (newHeight - currentFrame.height),
                            width: newWidth,
                            height: newHeight
                        )
                        window.setFrame(newFrame, display: true, animate: true)
                        
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                            self.manager.currentView = .workspace
                        }
                    }
                    
                    // Listen for green zoom button clicks to transition to workspace
                    NotificationCenter.default.addObserver(
                        forName: FloatingPanel.zoomRequestedNotification,
                        object: window,
                        queue: .main,
                        using: transitionHandler
                    )
                    
                    // Listen for app-wide workspace transition requests (e.g. from Save Sheet)
                    NotificationCenter.default.addObserver(
                        forName: Notification.Name("TransitionToWorkspace"),
                        object: nil,
                        queue: .main,
                        using: transitionHandler
                    )
                    
                    isFullScreen = window.styleMask.contains(.fullScreen)
                    updateWindowConstraints(window: window)
                }
            }
        )
        .ignoresSafeArea()
        .onChange(of: manager.keepTimerOnTop) { oldValue, newValue in
            guard let window = appWindow else { return }
            updateWindowConstraints(window: window)
        }
        .onChange(of: manager.currentView) { oldValue, newValue in
            guard let window = appWindow else { return }
            updateWindowConstraints(window: window)
        }
        .onChange(of: manager.appTheme) { oldValue, newValue in
            if let window = appWindow {
                updateWindowConstraints(window: window)
            }
            SettingsWindowManager.shared.updateTheme(newValue)
            SaveSheetWindowManager.shared.updateTheme(newValue)
            TutorialWindowManager.shared.updateTheme(newValue)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didEnterFullScreenNotification)) { notification in
            if let window = notification.object as? NSWindow, window == appWindow {
                isFullScreen = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didExitFullScreenNotification)) { notification in
            if let window = notification.object as? NSWindow, window == appWindow {
                isFullScreen = false
            }
        }
    }
    
    // MARK: - Primary Timer Screen
    private var timerView: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top Bar Actions (Row 1, containing custom traffic lights on left and actions on right)
                HStack {
                    // Custom macOS-style traffic lights with hover glyphs
                    HStack(spacing: 8) {
                        // Close Button (Red)
                        ZStack {
                            Circle()
                                .fill(Color(red: 1.0, green: 0.37, blue: 0.34))
                                .frame(width: 12, height: 12)
                                .overlay(Circle().stroke(Color.black.opacity(0.15), lineWidth: 0.5))
                            
                            if isTrafficLightHovered {
                                Image(systemName: "xmark")
                                    .font(.system(size: 7, weight: .heavy))
                                    .foregroundColor(Color.black.opacity(0.65))
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            NSApp.terminate(nil)
                        }
                        
                        // Minimize Button (Yellow)
                        ZStack {
                            Circle()
                                .fill(Color(red: 1.0, green: 0.74, blue: 0.18))
                                .frame(width: 12, height: 12)
                                .overlay(Circle().stroke(Color.black.opacity(0.15), lineWidth: 0.5))
                            
                            if isTrafficLightHovered {
                                Image(systemName: "minus")
                                    .font(.system(size: 8, weight: .heavy))
                                    .foregroundColor(Color.black.opacity(0.65))
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            self.appWindow?.miniaturize(nil)
                        }
                        
                        // Zoom/Workspace Button (Green)
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.15, green: 0.79, blue: 0.25))
                                .frame(width: 12, height: 12)
                                .overlay(Circle().stroke(Color.black.opacity(0.15), lineWidth: 0.5))
                            
                            if isTrafficLightHovered {
                                Image(systemName: "plus")
                                    .font(.system(size: 8, weight: .heavy))
                                    .foregroundColor(Color.black.opacity(0.65))
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            NotificationCenter.default.post(name: FloatingPanel.zoomRequestedNotification, object: self.appWindow)
                        }
                    }
                    .onHover { isTrafficLightHovered = $0 }
                    
                    Spacer()
                    
                    HStack(spacing: geometry.size.width < 250 ? 6 : 14) {
                        // Play/Pause Action
                        Button(action: {
                            if manager.isRunning {
                                manager.pauseTimer()
                            } else {
                                manager.startTimer()
                            }
                        }) {
                            Image(systemName: manager.isRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(manager.isRunning ? .accentColor : .primary)
                                .shadow(color: manager.isRunning ? .accentColor.opacity(0.5) : .clear, radius: 4)
                        }
                        .buttonStyle(.plain)
                        .onHover { isPlayHovered = $0 }
                        .scaleEffect(isPlayHovered ? 1.1 : 1.0)
                        
                        // Stop Action
                        if manager.timeElapsed > 0 || manager.isRunning {
                            Button(action: {
                                manager.stopAndPromptSave()
                            }) {
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                            .buttonStyle(.plain)
                            .onHover { isStopHovered = $0 }
                            .scaleEffect(isStopHovered ? 1.1 : 1.0)
                        }
                        
                        // Reset Action
                        Button(action: {
                            manager.resetTimer()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        .buttonStyle(.plain)
                        .onHover { isResetHovered = $0 }
                        .scaleEffect(isResetHovered ? 1.1 : 1.0)
                        
                        // Notes Action
                        Button(action: {
                            showNotesPopover.toggle()
                        }) {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(manager.activeNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .primary : .accentColor)
                                .shadow(color: manager.activeNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .clear : .accentColor.opacity(0.5), radius: 4)
                        }
                        .buttonStyle(.plain)
                        .onHover { isNotesHovered = $0 }
                        .scaleEffect(isNotesHovered ? 1.1 : 1.0)
                        .popover(isPresented: $showNotesPopover, arrowEdge: .bottom) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Session Notes")
                                        .font(.headline)
                                    Spacer()
                                    Button(action: { showNotesPopover = false }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                TextField("Type your notes here...", text: $manager.activeNotes, axis: .vertical)
                                    .textFieldStyle(.plain)
                                    .frame(minHeight: 80, alignment: .topLeading)
                                    .font(.body)
                                    .padding(8)
                                    .background(manager.appTheme == "Glass" ? Color.white.opacity(isDark ? 0.05 : 0.4) : Color.clear)
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                    )
                            }
                            .padding()
                            .frame(width: 250)
                        }
                        
                        if geometry.size.width >= 200 {
                            // Workspace Toggle Button
                            Button(action: {
                                NotificationCenter.default.post(name: Notification.Name("TransitionToWorkspace"), object: nil)
                            }) {
                                Image(systemName: "square.grid.2x2")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                            .buttonStyle(.plain)
                            .onHover { isWorkspaceHovered = $0 }
                            .scaleEffect(isWorkspaceHovered ? 1.1 : 1.0)
                        }
                    }
                }
                .padding(.horizontal, geometry.size.width < 250 ? 10 : 20)
                .padding(.top, 10)
                .padding(.bottom, 6)
                
                // Natural Language Duration Input (Row 2, placed below the traffic light / action buttons)
                HStack(spacing: 6) {
                    TextField(
                        "Timer Input",
                        text: $manager.inputTimerText,
                        prompt: Text(geometry.size.width < 180 ? "" : (geometry.size.width < 280 ? "Enter Timer" : "Enter Timer Here (\"20 min\", \"add 1 hour\", etc.)"))
                            .foregroundColor(isDark ? Color.white.opacity(0.4) : Color.black.opacity(0.5))
                    )
                    .textFieldStyle(.plain)
                    .font(.system(size: geometry.size.width < 180 ? 10 : 12, weight: .regular))
                    .foregroundColor(.primary)
                    .foregroundStyle(.primary)
                    .onSubmit {
                        manager.submitTimerInput()
                    }
                    
                    if !manager.inputTimerText.isEmpty && geometry.size.width >= 160 {
                        Button(action: { manager.inputTimerText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(6)
                .padding(.horizontal, geometry.size.width < 250 ? 10 : 20)
                .padding(.bottom, 8)
                
                Divider()
                    .opacity(0.15)
                
                // Large Digit Timer Center Display
                ZStack {
                    Color.clear.allowsHitTesting(false)
                    
                    VStack(spacing: 8) {
                        Text(formatTime(manager.timeRemaining))
                            .font(.system(size: min(48, geometry.size.width / 5.5), weight: .medium, design: .default))
                            .monospacedDigit()
                            .foregroundColor(.primary)
                            .shadow(color: .accentColor.opacity(0.35), radius: 8, x: 0, y: 0)
                            .contentShape(Rectangle())

                        
                        if geometry.size.height > 120 {
                            // Simple subtitle indicators
                            if manager.timerDuration > 0 {
                                HStack(spacing: 6) {
                                    Image(systemName: "hourglass.badge.plus")
                                    Text("Countdown Active")
                                }
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.06))
                                .cornerRadius(6)
                            } else if manager.isRunning {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 6, height: 6)
                                    Text("Stopwatch Tracking")
                                }
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.06))
                                .cornerRadius(6)
                            }
                        }
                    }
                    
                    if let feedback = manager.parseFeedback {
                        let fontSize = max(10, min(15, geometry.size.width / 16))
                        let hPadding = max(8, min(16, geometry.size.width / 15))
                        let vPadding = max(4, min(8, geometry.size.width / 30))
                        let cornerRadius = max(6, min(10, geometry.size.width / 24))
                        
                        Text(feedback)
                            .font(.system(size: fontSize, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, hPadding)
                            .padding(.vertical, vPadding)
                            .background(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .fill(manager.feedbackColor.opacity(0.92))
                                    .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                            )
                            .transition(.scale(scale: 0.85).combined(with: .opacity))
                            .zIndex(2)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    // MARK: - Window Management Helper
    
    private func updateWindowConstraints(window: NSWindow) {
        // Cancel any pending resize operation to coalesce consecutive events
        resizeWorkItem?.cancel()
        
        // If the window is currently in macOS Fullscreen space, we MUST exit it first
        // to prevent AppKit from resizing it inside the fullscreen Space (which causes black screens)
        if window.styleMask.contains(.fullScreen) {
            window.toggleFullScreen(nil)
            // Defer the constraint application slightly to allow fullscreen exit animation to finish
            let retryWorkItem = DispatchWorkItem {
                self.updateWindowConstraints(window: window)
            }
            self.resizeWorkItem = retryWorkItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: retryWorkItem)
            return
        }
        
        let workItem = DispatchWorkItem { [weak manager] in
            guard let manager = manager else { return }
            
            if manager.currentView == .workspace {
                window.level = .normal
                
                // Re-enable titled, closable, miniaturizable, resizable, and fullSizeContentView style
                window.styleMask.insert([.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView])
                window.styleMask.remove(.nonactivatingPanel)
                
                // Show standard buttons in workspace mode
                window.standardWindowButton(.closeButton)?.isHidden = false
                window.standardWindowButton(.miniaturizeButton)?.isHidden = false
                window.standardWindowButton(.zoomButton)?.isHidden = false
                
                let workspaceSize = NSSize(width: 850, height: 550)
                window.minSize = workspaceSize
                window.maxSize = NSSize(width: 10000, height: 10000)
                
                // Draggable by background in workspace too
                window.isMovableByWindowBackground = true
                
                // Enable native full screen so the green button triggers real macOS full screen
                window.collectionBehavior = [.fullScreenPrimary]
            } else {
                window.level = .screenSaver
                
                // Normal timer mode — remove titled and closable. Keep miniaturizable and resizable.
                window.styleMask.remove([.titled, .closable, .fullSizeContentView])
                window.styleMask.insert([.resizable, .nonactivatingPanel, .miniaturizable])
                
                // Restore timer collection behavior
                window.collectionBehavior = [
                    .canJoinAllSpaces,
                    .fullScreenAuxiliary,
                    .stationary,
                    .ignoresCycle
                ]
                
                // Hide standard buttons in normal mode
                window.standardWindowButton(.closeButton)?.isHidden = true
                window.standardWindowButton(.miniaturizeButton)?.isHidden = true
                window.standardWindowButton(.zoomButton)?.isHidden = true
                
                let normalSize = NSSize(width: 210, height: 120)
                window.minSize = normalSize
                window.maxSize = normalSize
                
                let newFrame = self.getTopRightFrame(for: window, size: normalSize)
                window.setFrame(newFrame, display: true, animate: true)
                
                // Draggable by clicking anywhere on background
                window.isMovableByWindowBackground = true
            }
            
            // Ensure titlebar style matches the current mode
            configureTitlebar(for: window, currentView: manager.currentView)
        }
        
        self.resizeWorkItem = workItem
        DispatchQueue.main.async(execute: workItem)
    }
    
    // Format duration into HH:MM:SS
    private func formatTime(_ time: TimeInterval) -> String {
        let hrs = Int(time) / 3600
        let mins = (Int(time) % 3600) / 60
        let secs = Int(time) % 60
        return String(format: "%02d:%02d:%02d", hrs, mins, secs)
    }
    
    private func getTopRightFrame(for window: NSWindow, size: NSSize) -> NSRect {
        guard let screen = window.screen ?? NSScreen.main ?? NSScreen.screens.first else {
            return NSRect(x: 100, y: 100, width: size.width, height: size.height)
        }
        let visibleFrame = screen.visibleFrame
        let padding: CGFloat = 20
        
        return NSRect(
            x: visibleFrame.maxX - size.width - padding,
            y: visibleFrame.maxY - size.height - padding,
            width: size.width,
            height: size.height
        )
    }
}

private func configureTitlebar(for window: NSWindow, currentView: AppView) {
    // Normal/Workspace mode: standard native macOS title bar with traffic lights
    window.titleVisibility = .hidden // Hide title text but keep the bar
    if currentView == .timer {
        window.titlebarAppearsTransparent = true
        if !window.styleMask.contains(.fullSizeContentView) {
            window.styleMask.insert(.fullSizeContentView)
        }
    } else {
        window.titlebarAppearsTransparent = false
        if window.styleMask.contains(.fullSizeContentView) {
            window.styleMask.remove(.fullSizeContentView)
        }
    }
}

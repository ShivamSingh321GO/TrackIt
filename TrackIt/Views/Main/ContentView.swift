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
    
    @State private var isPlayHovered = false
    @State private var isResetHovered = false
    @State private var isStopHovered = false
    @State private var isCompactHovered = false
    @State private var isWorkspaceHovered = false
    @State private var isNotesHovered = false
    @State private var isHoveringCompact = false
    @State private var showNotesPopover = false
    
    @State private var appWindow: NSWindow? = nil
    @State private var resizeWorkItem: DispatchWorkItem? = nil
    
    var isDark: Bool {
        if manager.appTheme == "Dark" {
            return true
        } else if manager.appTheme == "Light" {
            return false
        } else {
            return colorScheme == .dark
        }
    }
    
    var body: some View {
        ZStack {
            DragBackground(color: isDark ? NSColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 1.0) : NSColor(red: 0.95, green: 0.96, blue: 0.98, alpha: 1.0))
            
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
        .frame(
            minWidth: manager.isCompactMode ? 80 : nil,
            maxWidth: manager.isCompactMode ? 80 : .infinity,
            minHeight: manager.isCompactMode ? 28 : nil,
            maxHeight: manager.isCompactMode ? 28 : .infinity
        )
        .onChange(of: manager.showSaveSheet) { oldValue, newValue in
            if newValue {
                SaveSheetWindowManager.shared.showSaveSheet(manager: manager, duration: manager.timeElapsed)
            } else {
                SaveSheetWindowManager.shared.closeSaveSheet()
            }
        }

        .sheet(isPresented: $manager.showTutorialSheet) {
            TutorialSheet(manager: manager)
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: manager.currentView)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: manager.isCompactMode)
        .background(
            WindowAccessor { window in
                if self.appWindow == nil {
                    self.appWindow = window
                    let managerRef = self.manager
                    // Initial titlebar configuration based on current mode
                    configureTitlebar(for: window, isCompact: managerRef.isCompactMode)
                    window.isMovableByWindowBackground = false // Disable system titlebar/background dragging to prevent double-click zoom
                    window.level = .screenSaver // High enough to overlay full-screen spaces
                    window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
                    
                    // Keep titlebar style synchronized on focus changes and resizes
                    NotificationCenter.default.addObserver(
                        forName: NSWindow.didBecomeKeyNotification,
                        object: window,
                        queue: .main
                    ) { _ in
                        configureTitlebar(for: window, isCompact: managerRef.isCompactMode)
                    }
                    NotificationCenter.default.addObserver(
                        forName: NSWindow.didResignKeyNotification,
                        object: window,
                        queue: .main
                    ) { _ in
                        configureTitlebar(for: window, isCompact: managerRef.isCompactMode)
                    }
                    NotificationCenter.default.addObserver(
                        forName: NSWindow.didResizeNotification,
                        object: window,
                        queue: .main
                    ) { _ in
                        configureTitlebar(for: window, isCompact: managerRef.isCompactMode)
                    }
                    
                    updateWindowConstraints(window: window)
                }
            }
        )
        .onChange(of: manager.isCompactMode) { oldValue, newValue in
            guard let window = appWindow else { return }
            updateWindowConstraints(window: window)
        }
        .onChange(of: manager.keepTimerOnTop) { oldValue, newValue in
            guard let window = appWindow else { return }
            updateWindowConstraints(window: window)
        }
        .onChange(of: manager.currentView) { oldValue, newValue in
            guard let window = appWindow else { return }
            // Only handle timer transition asynchronously; workspace is handled synchronously pre-switch
            if newValue == .timer {
                updateWindowConstraints(window: window)
            }
        }
    }
    
    // MARK: - Primary Timer Screen
    private var timerView: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                if !manager.isCompactMode {
                    // Top Bar
                    HStack(spacing: geometry.size.width < 250 ? 6 : 16) {
                        // Natural Language Duration Input
                        TextField(
                            "Timer Input",
                            text: $manager.inputTimerText,
                            prompt: Text(geometry.size.width < 180 ? "" : (geometry.size.width < 280 ? "Enter Timer" : "Enter Timer Here (\"20 min\", \"add 1 hour\", etc.)"))
                                .foregroundColor(isDark ? Color.white.opacity(0.4) : Color.black.opacity(0.5))
                        )
                        .textFieldStyle(.plain)
                        .font(.system(size: geometry.size.width < 180 ? 10 : 13, weight: .regular))
                        .foregroundColor(isDark ? .white : .black)
                        .foregroundStyle(isDark ? .white : .black)
                        .onSubmit {
                            manager.submitTimerInput()
                        }
                        
                        if !manager.inputTimerText.isEmpty && geometry.size.width >= 160 {
                            Button(action: { manager.inputTimerText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(isDark ? .white : .black)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Spacer()
                        
                        // Top Bar Actions
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
                                    .foregroundColor(manager.isRunning ? .accentColor : (isDark ? .white : .black))
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
                                        .foregroundColor(isDark ? .white : .black)
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
                                    .foregroundColor(isDark ? .white : .black)
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
                                    .foregroundColor(manager.activeNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? (isDark ? .white : .black) : .accentColor)
                            }
                            .buttonStyle(.plain)
                            .onHover { isNotesHovered = $0 }
                            .scaleEffect(isNotesHovered ? 1.1 : 1.0)
                            .popover(isPresented: $showNotesPopover, arrowEdge: .bottom) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Active Notes")
                                            .font(.headline)
                                        Spacer()
                                        Button("Done") {
                                            showNotesPopover = false
                                        }
                                        .buttonStyle(.plain)
                                        .foregroundColor(.accentColor)
                                    }
                                    TextEditor(text: $manager.activeNotes)
                                        .font(.system(size: 12))
                                        .scrollContentBackground(.hidden)
                                        .padding(6)
                                        .background(Color(NSColor.textBackgroundColor))
                                        .cornerRadius(6)
                                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                                }
                                .padding()
                                .frame(width: 230, height: 160)
                            }
                            
                            // Compact Mode Toggle Button
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    manager.isCompactMode = true
                                }
                            }) {
                                Image(systemName: "arrow.down.right.and.arrow.up.left")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(isDark ? .white : .black)
                            }
                            .buttonStyle(.plain)
                            .onHover { isCompactHovered = $0 }
                            .scaleEffect(isCompactHovered ? 1.1 : 1.0)
                            
                            if geometry.size.width >= 200 {
                                // Workspace Toggle Button
                                Button(action: {
                                    if let window = appWindow {
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
                                    }
                                    
                                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                                        manager.isCompactMode = false
                                        manager.currentView = .workspace
                                    }
                                }) {
                                    Image(systemName: "square.grid.2x2")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(isDark ? .white : .black)
                                }
                                .buttonStyle(.plain)
                                .onHover { isWorkspaceHovered = $0 }
                                .scaleEffect(isWorkspaceHovered ? 1.1 : 1.0)
                            }
                        }
                    }
                    .padding(.horizontal, geometry.size.width < 250 ? 10 : 20)
                    .padding(.vertical, geometry.size.width < 250 ? 6 : 10)
                    .background((isDark ? Color(red: 0.18, green: 0.18, blue: 0.22) : Color(red: 0.80, green: 0.81, blue: 0.87)).allowsHitTesting(false)) // Match user's color exactly
                    
                    Divider()
                }
                
                // Large Digit Timer Center Display
                ZStack {
                    (isDark ? Color(red: 0.11, green: 0.11, blue: 0.13) : Color(red: 0.95, green: 0.96, blue: 0.98)).allowsHitTesting(false)
                        .onHover { hovering in
                            isHoveringCompact = hovering
                        }
                    
                    VStack(spacing: manager.isCompactMode ? 0 : 8) {
                        if manager.isCompactMode && isHoveringCompact {
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    manager.isCompactMode = false
                                }
                            }) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(isDark ? .white : .black)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        } else {
                            Text(formatTime(manager.timeRemaining))
                                .font(.system(size: manager.isCompactMode ? 11 : min(48, geometry.size.width / 5.5), weight: .medium, design: .default))
                                .monospacedDigit()
                                .foregroundColor(isDark ? Color(red: 0.90, green: 0.90, blue: 0.95) : Color(red: 0.23, green: 0.23, blue: 0.27)) // Adaptive Charcoal/Light Gray Text
                                .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if manager.isRunning {
                                        manager.pauseTimer()
                                    } else {
                                        manager.startTimer()
                                    }
                                }
                        }
                        
                        if !manager.isCompactMode && geometry.size.height > 120 {
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
            
            if manager.isCompactMode {
                // Keep window on top so they can work with it visible in any corner
                window.level = .screenSaver
                
                // Adjust frame to exact compact size
                let compactSize = NSSize(width: 80, height: 28)
                window.minSize = compactSize
                window.maxSize = compactSize
                
                let newFrame = self.getTopRightFrame(for: window, size: compactSize)
                // Hide standard buttons in compact mode
                window.standardWindowButton(.closeButton)?.isHidden = true
                window.standardWindowButton(.miniaturizeButton)?.isHidden = true
                window.standardWindowButton(.zoomButton)?.isHidden = true
                
                window.setFrame(newFrame, display: true, animate: true)
                
                // Disable resizing in compact mode
                window.styleMask.remove(.resizable)
            } else if manager.currentView == .workspace {
                // Keep window on top per user request
                window.level = .screenSaver
                
                // Re-enable resizable style
                window.styleMask.insert(.resizable)
                
                // Show standard buttons in normal mode
                window.standardWindowButton(.closeButton)?.isHidden = false
                window.standardWindowButton(.miniaturizeButton)?.isHidden = false
                window.standardWindowButton(.zoomButton)?.isHidden = false
                
                let workspaceSize = NSSize(width: 850, height: 550)
                window.minSize = workspaceSize
                window.maxSize = NSSize(width: 10000, height: 10000)
                
                let currentFrame = window.frame
                let newWidth = max(currentFrame.width, workspaceSize.width)
                let newHeight = max(currentFrame.height, workspaceSize.height)
                let newFrame = self.getTopRightFrame(for: window, size: NSSize(width: newWidth, height: newHeight))
                window.setFrame(newFrame, display: true, animate: true)
            } else {
                // Keep window on top per user request
                window.level = .screenSaver
                
                // Disable resizing in normal timer mode to keep it as a fixed-size widget
                window.styleMask.remove(.resizable)
                
                // Show standard buttons in normal mode
                window.standardWindowButton(.closeButton)?.isHidden = false
                window.standardWindowButton(.miniaturizeButton)?.isHidden = false
                window.standardWindowButton(.zoomButton)?.isHidden = false
                
                let normalSize = NSSize(width: 240, height: 140)
                window.minSize = normalSize
                window.maxSize = normalSize
                
                let newFrame = self.getTopRightFrame(for: window, size: normalSize)
                window.setFrame(newFrame, display: true, animate: true)
            }
            
            // Ensure titlebar style matches the current mode
            configureTitlebar(for: window, isCompact: manager.isCompactMode)
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
        let screen = window.screen ?? NSScreen.main ?? NSScreen()
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

private func configureTitlebar(for window: NSWindow, isCompact: Bool) {
    if isCompact {
        // Compact mode: transparent borderless look for the floating pill
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
    } else {
        // Normal/Workspace mode: standard native macOS title bar with traffic lights
        window.titleVisibility = .hidden // Hide title text but keep the bar
        window.titlebarAppearsTransparent = false
        window.styleMask.remove(.fullSizeContentView)
    }
}

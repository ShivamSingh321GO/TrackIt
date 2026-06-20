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
    @State private var isResetHovered = false
    @State private var isStopHovered = false
    @State private var isWorkspaceHovered = false
    @State private var isNotesHovered = false
    @State private var showNotesPopover = false
    
    @State private var appWindow: NSWindow? = nil
    @State private var resizeWorkItem: DispatchWorkItem? = nil
    
    var body: some View {
        ZStack {
            DragBackground(color: isDark ? NSColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 1.0) : NSColor.white)
            
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
                    configureTitlebar(for: window)
                    
                    // The FloatingPanel already handles: level, collectionBehavior,
                    // isMovableByWindowBackground, hidesOnDeactivate, non-activating style.
                    // We just need to keep titlebar style synchronized.
                    NotificationCenter.default.addObserver(
                        forName: NSWindow.didBecomeKeyNotification,
                        object: window,
                        queue: .main
                    ) { _ in
                        configureTitlebar(for: window)
                    }
                    NotificationCenter.default.addObserver(
                        forName: NSWindow.didResignKeyNotification,
                        object: window,
                        queue: .main
                    ) { _ in
                        configureTitlebar(for: window)
                    }
                    // NOTE: Do NOT observe didResizeNotification here.
                    // configureTitlebar modifies styleMask, which triggers another
                    // resize/constraint pass and causes a re-entrancy crash when
                    // dragging the window.
                    
                    // Listen for green zoom button clicks to transition to workspace
                    NotificationCenter.default.addObserver(
                        forName: FloatingPanel.zoomRequestedNotification,
                        object: window,
                        queue: .main
                    ) { _ in
                        guard let window = self.appWindow else { return }
                        // Expand to workspace size first
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
                    
                    updateWindowConstraints(window: window)
                }
            }
        )
        .onChange(of: manager.keepTimerOnTop) { oldValue, newValue in
            guard let window = appWindow else { return }
            updateWindowConstraints(window: window)
        }
        .onChange(of: manager.currentView) { oldValue, newValue in
            guard let window = appWindow else { return }
            updateWindowConstraints(window: window)
        }
    }
    
    // MARK: - Primary Timer Screen
    private var timerView: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
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
                                        manager.currentView = .workspace
                                    }
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
                    .padding(.vertical, geometry.size.width < 250 ? 6 : 10)
                    .background((isDark ? Color(red: 0.11, green: 0.11, blue: 0.15) : Color(white: 0.96)).allowsHitTesting(false)) 
                    
                    Divider()
                
                // Large Digit Timer Center Display
                ZStack {
                    (isDark ? Color(red: 0.06, green: 0.06, blue: 0.08) : Color.white).allowsHitTesting(false)
                    
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
            
            // Always keep the panel floating above everything (including fullscreen apps)
            window.level = .screenSaver
            
            if manager.currentView == .workspace {
                // Re-enable resizable style
                window.styleMask.insert(.resizable)
                
                // Show standard buttons in workspace mode
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
                
                // Draggable by background in workspace too
                window.isMovableByWindowBackground = true
                
                // Enable full screen capability for the green button
                window.collectionBehavior.remove(.fullScreenAuxiliary)
                window.collectionBehavior.insert(.fullScreenPrimary)
            } else {
                // Normal timer mode — keep .resizable so the green zoom button stays active
                window.styleMask.insert(.resizable)
                
                // Show standard buttons in normal mode
                window.standardWindowButton(.closeButton)?.isHidden = false
                window.standardWindowButton(.miniaturizeButton)?.isHidden = false
                window.standardWindowButton(.zoomButton)?.isHidden = false
                
                let normalSize = NSSize(width: 240, height: 140)
                window.minSize = normalSize
                window.maxSize = normalSize
                
                let newFrame = self.getTopRightFrame(for: window, size: normalSize)
                window.setFrame(newFrame, display: true, animate: true)
                
                // Draggable by clicking anywhere on background
                window.isMovableByWindowBackground = true
                
                // Disable full screen in timer mode, keep it as overlay
                window.collectionBehavior.remove(.fullScreenPrimary)
                window.collectionBehavior.insert(.fullScreenAuxiliary)
            }
            
            // Ensure titlebar style matches the current mode
            configureTitlebar(for: window)
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

private func configureTitlebar(for window: NSWindow) {
    // Normal/Workspace mode: standard native macOS title bar with traffic lights
    window.titleVisibility = .hidden // Hide title text but keep the bar
    window.titlebarAppearsTransparent = false
    // Only mutate styleMask if it actually contains the flag to avoid
    // triggering an unnecessary constraint/layout pass.
    if window.styleMask.contains(.fullSizeContentView) {
        window.styleMask.remove(.fullSizeContentView)
    }
}

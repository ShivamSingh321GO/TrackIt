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
        if manager.appTheme == "Light" {
            return false
        } else {
            return true
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
            if manager.appTheme == "Glass" {
                VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            } else {
                DragBackground(color: isDark ? NSColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 1.0) : NSColor.white)
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
        .preferredColorScheme(manager.appTheme == "Light" ? .light : .dark)
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
                        configureTitlebar(for: window, currentView: managerRef.currentView)
                    }
                    NotificationCenter.default.addObserver(
                        forName: NSWindow.didResignKeyNotification,
                        object: window,
                        queue: .main
                    ) { _ in
                        configureTitlebar(for: window, currentView: managerRef.currentView)
                    }
                    // NOTE: Do NOT observe didResizeNotification here.
                    // configureTitlebar modifies styleMask, which triggers another
                    // resize/constraint pass and causes a re-entrancy crash when
                    // dragging the window.
                    
                    let transitionHandler: (Notification) -> Void = { _ in
                        guard let window = self.appWindow else { return }
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
                // Header Bar (aligned vertically with native traffic lights)
                HStack(spacing: 12) {
                    // Spacer to clear the close/minimize/zoom buttons in the top-left
                    Spacer()
                        .frame(width: 70)
                    
                    Spacer()
                    
                    // Header Actions
                    HStack(spacing: 10) {
                        // Play/Pause Action
                        Button(action: {
                            if manager.isRunning {
                                manager.pauseTimer()
                            } else {
                                manager.startTimer()
                            }
                        }) {
                            Image(systemName: manager.isRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 13, weight: .bold))
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
                                    .font(.system(size: 12, weight: .semibold))
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
                                .font(.system(size: 12, weight: .semibold))
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
                                .font(.system(size: 12, weight: .semibold))
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
                        
                        // Workspace Action
                        Button(action: {
                            NotificationCenter.default.post(name: Notification.Name("TransitionToWorkspace"), object: nil)
                        }) {
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        .buttonStyle(.plain)
                        .onHover { isWorkspaceHovered = $0 }
                        .scaleEffect(isWorkspaceHovered ? 1.1 : 1.0)
                    }
                }
                .frame(height: 28)
                .padding(.horizontal, 12)
                .padding(.top, 4)
                
                // Natural Language Duration Input (Enter Timer)
                HStack(spacing: 8) {
                    TextField(
                        "Timer Input",
                        text: $manager.inputTimerText,
                        prompt: Text("Enter Timer")
                            .foregroundColor(isDark ? Color.white.opacity(0.4) : Color.black.opacity(0.5))
                    )
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.primary)
                    .onSubmit {
                        manager.submitTimerInput()
                    }
                    
                    if !manager.inputTimerText.isEmpty {
                        Button(action: { manager.inputTimerText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.primary.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(manager.appTheme == "Glass" ? Color.white.opacity(0.08) : Color.primary.opacity(0.06))
                )
                .padding(.horizontal, 12)
                .padding(.top, 4)
                
                // Large Digit Timer Center Display
                ZStack {
                    // Background placeholder (clear if glass so blur shows, otherwise solid color)
                    if manager.appTheme != "Glass" {
                        (isDark ? Color(red: 0.06, green: 0.06, blue: 0.08) : Color.white).allowsHitTesting(false)
                    }
                    
                    VStack(spacing: 4) {
                        Text(formatTime(manager.timeRemaining))
                            .font(.system(size: min(44, geometry.size.width / 5.5), weight: .medium, design: .default))
                            .monospacedDigit()
                            .foregroundColor(.primary)
                            .shadow(color: .accentColor.opacity(manager.appTheme == "Glass" ? 0.2 : 0.35), radius: 8, x: 0, y: 0)
                            .contentShape(Rectangle())
                        
                        if geometry.size.height > 100 {
                            if manager.timerDuration > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "hourglass.badge.plus")
                                    Text("Countdown Active")
                                }
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                            } else if manager.isRunning {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 5, height: 5)
                                    Text("Stopwatch Tracking")
                                }
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    if let feedback = manager.parseFeedback {
                        let fontSize = max(10, min(14, geometry.size.width / 16))
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
                .padding(.bottom, 6)
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
            
            // Ensure titlebar style matches the current mode FIRST so layout bounds are calculated correctly
            configureTitlebar(for: window, currentView: manager.currentView)
            
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
                
                let normalSize = NSSize(width: 210, height: 120)
                
                // Allow the window frame to animate resize smoothly without snapping constraints
                window.minSize = normalSize
                window.maxSize = NSSize(width: 10000, height: 10000)
                
                let newFrame = self.getTopRightFrame(for: window, size: normalSize)
                window.setFrame(newFrame, display: true, animate: true)
                
                // Lock window constraints after the transition animation finishes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    guard manager.currentView == .timer else { return }
                    window.minSize = normalSize
                    window.maxSize = normalSize
                }
                
                // Draggable by clicking anywhere on background
                window.isMovableByWindowBackground = true
                
                // Disable full screen in timer mode, keep it as overlay
                window.collectionBehavior.remove(.fullScreenPrimary)
                window.collectionBehavior.insert(.fullScreenAuxiliary)
            }
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

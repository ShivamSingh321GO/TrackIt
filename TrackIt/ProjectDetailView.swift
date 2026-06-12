//
//  ProjectDetailView.swift
//  TrackIt
//
//  Created by Antigravity on 6/4/26.
//

import SwiftUI

struct ProjectDetailView: View {
    let project: Project
    @Bindable var manager: SessionFlowManager
    let onBack: () -> Void
    
    @State private var showPlanSessionSheet: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Back Button Navigation Bar
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back to Projects")
                    }
                    .font(.body)
                    .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding(.top, 8)
            
            // Project Title Section
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(hex: project.colorHex))
                    .frame(width: 14, height: 14)
                
                Text(project.name)
                    .font(.title)
                    .bold()
                
                Spacer()
                
                Button(action: { showPlanSessionSheet = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Plan Session")
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            
            Divider()
            
            // Unified chronological sessions timeline
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    let sortedSessions = getSortedSessions()
                    
                    if sortedSessions.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                            Text("No sessions recorded or planned for this project yet.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button(action: { showPlanSessionSheet = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                    Text("Plan Your First Session")
                                }
                            }
                            .buttonStyle(.bordered)
                            .padding(.top, 4)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(Array(sortedSessions.enumerated()), id: \.element.id) { index, session in
                            ProjectTimelineRow(
                                session: session,
                                isFirst: index == 0,
                                isLast: index == sortedSessions.count - 1,
                                manager: manager
                            )
                        }
                    }
                }
                .padding(.trailing, 8)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .sheet(isPresented: $showPlanSessionSheet) {
            ProjectPlanSessionSheet(manager: manager, project: project)
        }
    }
    
    private func getSortedSessions() -> [Session] {
        let projectSessions: [Session] = manager.sessions.filter { (session: Session) -> Bool in
            session.projectRef == project.id
        }
        return projectSessions.sorted(by: { (s1: Session, s2: Session) -> Bool in
            let d1 = s1.datePlanned ?? s1.date
            let d2 = s2.datePlanned ?? s2.date
            return d1 < d2
        })
    }
}

// MARK: - Project Timeline Row View

struct ProjectTimelineRow: View {
    let session: Session
    let isFirst: Bool
    let isLast: Bool
    let manager: SessionFlowManager
    
    @State private var isNotesExpanded: Bool = false
    @State private var isHovered: Bool = false
    
    private var hasNotes: Bool {
        !session.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Timeline line & checkpoint dot column
            ZStack(alignment: .top) {
                // Continuous line
                GeometryReader { geo in
                    VStack(spacing: 0) {
                        if isFirst {
                            Color.clear.frame(width: 2, height: 17)
                        } else {
                            Rectangle()
                                .fill(lineColor)
                                .frame(width: 2, height: 17)
                        }
                        
                        if isLast {
                            Color.clear.frame(width: 2)
                        } else {
                            Rectangle()
                                .fill(lineColor)
                                .frame(width: 2)
                        }
                    }
                }
                .frame(width: 2)
                
                dotView
                    .padding(.top, 10)
            }
            .frame(width: 20)
            
            // Session Card Content
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(session.title)
                                .fontWeight(.semibold)
                                .foregroundColor(session.status == .completed ? .secondary : .primary)
                                .strikethrough(session.status == .completed)
                            
                            // Notes indicator icon
                            if hasNotes {
                                Image(systemName: isNotesExpanded ? "note.text" : "note.text")
                                    .font(.system(size: 10))
                                    .foregroundColor(isNotesExpanded ? .accentColor : .secondary.opacity(0.6))
                                    .symbolEffect(.bounce, value: isNotesExpanded)
                            }
                        }
                        
                        HStack(spacing: 8) {
                            Text(session.status == .completed ? "Tracked: \(formatDuration(session.duration))" : "Target: \(formatDuration(session.duration))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if session.status == .completed {
                                Text("•")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(session.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if session.status == .completed {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                            Text("Done")
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(6)
                    } else if session.status == .running {
                        HStack(spacing: 4) {
                            Image(systemName: "hourglass.badge.ellipsis")
                            Text("Active")
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(6)
                    } else {
                        // Play Button to start the planned session
                        Button(action: {
                            manager.timerDuration = session.duration
                            manager.timeElapsed = 0
                            manager.inputTimerText = ""
                            
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                manager.currentView = .timer
                            }
                            
                            DispatchQueue.main.async {
                                manager.startPlannedSession(session)
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "play.fill")
                                Text("Start")
                            }
                            .font(.footnote)
                            .bold()
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Delete button
                    Button(action: {
                        withAnimation {
                            manager.deleteSession(id: session.id)
                        }
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 4)
                }
                .padding(10)
                
                // Expandable Notes Panel
                if isNotesExpanded && hasNotes {
                    VStack(alignment: .leading, spacing: 8) {
                        Divider()
                            .padding(.horizontal, 4)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "text.quote")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.accentColor.opacity(0.7))
                            
                            Text("SESSION NOTES")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                                .tracking(0.5)
                        }
                        .padding(.horizontal, 10)
                        
                        Text(session.notes)
                            .font(.system(size: 12.5))
                            .foregroundColor(.primary.opacity(0.85))
                            .lineSpacing(4)
                            .textSelection(.enabled)
                            .padding(.horizontal, 10)
                            .padding(.bottom, 2)
                    }
                    .padding(.vertical, 8)
                    .transition(
                        .asymmetric(
                            insertion: .opacity
                                .combined(with: .move(edge: .top))
                                .combined(with: .scale(scale: 0.97, anchor: .top)),
                            removal: .opacity
                                .combined(with: .move(edge: .top))
                                .combined(with: .scale(scale: 0.97, anchor: .top))
                        )
                    )
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(isHovered && hasNotes ? 0.7 : 0.5))
            )
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isNotesExpanded ? Color.accentColor.opacity(0.25) :
                            (session.status == .completed ? Color.green.opacity(0.15) : Color.secondary.opacity(0.08)),
                        lineWidth: isNotesExpanded ? 1.5 : 1
                    )
            )
            .contentShape(Rectangle())
            .onTapGesture {
                guard hasNotes else { return }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                    isNotesExpanded.toggle()
                }
            }
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
                if hovering && hasNotes {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            .padding(.bottom, 6)
        }
    }
    
    private var lineColor: Color {
        if session.status == .completed {
            return .green.opacity(0.3)
        } else if session.status == .running {
            return .accentColor.opacity(0.3)
        } else {
            return .secondary.opacity(0.15)
        }
    }
    
    @ViewBuilder
    private var dotView: some View {
        if session.status == .completed {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 14))
                .background(Circle().fill(Color(NSColor.windowBackgroundColor)))
        } else if session.status == .running {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(Color.accentColor.opacity(0.3), lineWidth: 3)
                        .scaleEffect(1.2)
                )
        } else {
            Circle()
                .stroke(Color.secondary.opacity(0.4), lineWidth: 2)
                .background(Circle().fill(Color(NSColor.windowBackgroundColor)))
                .frame(width: 10, height: 10)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        if totalSeconds <= 0 {
            return "0 sec"
        }
        
        let hrs = totalSeconds / 3600
        let mins = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        
        var parts: [String] = []
        if hrs > 0 {
            parts.append("\(hrs)h")
        }
        if mins > 0 {
            parts.append("\(mins)min")
        }
        if secs > 0 {
            parts.append("\(secs)sec")
        }
        
        return parts.joined(separator: " ")
    }
}

struct ProjectPlanSessionSheet: View {
    @Bindable var manager: SessionFlowManager
    let project: Project
    
    @State private var plannedSessionTitle: String = ""
    @State private var plannedSessionDurationText: String = "20 min"
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Plan a Future Session")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Session Task Name")
                        .font(.caption).foregroundColor(.secondary)
                    TextField("e.g. Design Login Screen", text: $plannedSessionTitle)
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(NSColor.separatorColor), lineWidth: 1))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Target Duration")
                        .font(.caption).foregroundColor(.secondary)
                    TextField("e.g. 45 min, 1h 30m", text: $plannedSessionDurationText)
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(NSColor.separatorColor), lineWidth: 1))
                }
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Save Plan") {
                    let parsed = manager.parseDuration(plannedSessionDurationText)
                    let duration = parsed?.duration ?? 1800 // 30m default
                    
                    manager.planSession(
                        title: plannedSessionTitle.isEmpty ? "Planned Work Block" : plannedSessionTitle,
                        duration: duration,
                        projectId: project.id
                    )
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(plannedSessionTitle.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 350)
    }
}

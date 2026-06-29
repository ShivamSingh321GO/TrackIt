import SwiftUI

struct PlannedSessionRow: View {
    let session: Session
    let manager: SessionFlowManager
    
    @Environment(\.colorScheme) var colorScheme
    var isDark: Bool {
        if manager.appTheme == "Dark" { return true }
        if manager.appTheme == "Light" { return false }
        return colorScheme == .dark
    }
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.title)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    if let projId = session.projectRef,
                       let proj = manager.projects.first(where: { $0.id == projId }) {
                        HStack(spacing: 4) {
                            Circle().fill(Color(hex: proj.colorHex)).frame(width: 6, height: 6)
                            Text(proj.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Standalone")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Target: \(formatDuration(session.duration))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Tags
                let sessionTags = (session.tagRefs ?? []).compactMap { tagId in
                    manager.tags.first { $0.id == tagId }
                }
                if !sessionTags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(sessionTags) { tag in
                            TagChip(tag: tag)
                        }
                    }
                }
            }
            Spacer()
            
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
            .padding(.trailing, 8)
            
            // Play/Start Button
            Button(action: {
                // Set manager countdown details
                manager.timerDuration = session.duration
                manager.timeElapsed = 0
                manager.inputTimerText = ""
                
                // Go to Timer view first to ensure a clean visual transition before modifying view hierarchy
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    manager.currentView = .timer
                }
                
                // Defer starting the session and updating its status to .running slightly
                // to avoid deallocating this row view while executing its button action.
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
                .padding(.vertical, 6)
                .background(Color.accentColor.opacity((manager.isRunning || manager.timeElapsed > 0) ? 0.5 : 1.0))
                .foregroundColor(.white.opacity((manager.isRunning || manager.timeElapsed > 0) ? 0.7 : 1.0))
                .cornerRadius(6)
            }
            .disabled(manager.isRunning || manager.timeElapsed > 0)
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            manager.appTheme == "Glass"
            ? Color.white.opacity(0.06)
            : (isDark ? Color(red: 0.10, green: 0.10, blue: 0.12) : Color(red: 0.97, green: 0.97, blue: 0.98))
        )
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.1), lineWidth: 1))
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

struct CompletedSessionRow: View {
    let session: Session
    let manager: SessionFlowManager
    
    @Environment(\.colorScheme) var colorScheme
    var isDark: Bool {
        if manager.appTheme == "Dark" { return true }
        if manager.appTheme == "Light" { return false }
        return colorScheme == .dark
    }
    
    @State private var isNotesExpanded: Bool = false
    @State private var isHovered: Bool = false
    @State private var isEditingNotes: Bool = false
    @State private var editedNotes: String = ""
    
    private var hasNotes: Bool {
        !session.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main card content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    HStack(spacing: 6) {
                        Text(session.title)
                            .fontWeight(.semibold)
                        
                        // Notes indicator
                        if hasNotes {
                            Image(systemName: "note.text")
                                .font(.system(size: 10))
                                .foregroundColor(isNotesExpanded ? .accentColor : .secondary.opacity(0.5))
                                .symbolEffect(.bounce, value: isNotesExpanded)
                        }
                    }
                    
                    Spacer()
                    Text(formatDuration(session.duration))
                        .font(.system(.body, design: .monospaced))
                        .bold()
                    
                    // Add/Edit notes button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if !isNotesExpanded {
                                isNotesExpanded = true
                                isEditingNotes = true
                                editedNotes = session.notes
                            } else {
                                if isEditingNotes {
                                    isEditingNotes = false
                                    if session.notes.isEmpty {
                                        isNotesExpanded = false
                                    }
                                } else {
                                    isEditingNotes = true
                                    editedNotes = session.notes
                                }
                            }
                        }
                    }) {
                        Image(systemName: "square.and.pencil")
                            .font(.footnote)
                            .foregroundColor(isEditingNotes ? .accentColor : .secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 8)
                    .help(session.notes.isEmpty ? "Add notes" : "Edit notes")
                    
                    Button(action: {
                        withAnimation {
                            manager.deleteSession(id: session.id)
                        }
                    }) {
                        Image(systemName: "trash")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 8)
                }
                
                HStack(spacing: 8) {
                    if let projId = session.projectRef,
                       let proj = manager.projects.first(where: { $0.id == projId }) {
                        HStack(spacing: 4) {
                            Circle().fill(Color(hex: proj.colorHex)).frame(width: 6, height: 6)
                            Text(proj.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Standalone")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("•")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    
                    Text(session.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Tags
                let sessionTags = (session.tagRefs ?? []).compactMap { tagId in
                    manager.tags.first { $0.id == tagId }
                }
                if !sessionTags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(sessionTags) { tag in
                            TagChip(tag: tag)
                        }
                    }
                }
            }
            .padding(12)
            
            // Expandable Notes Panel
            if isNotesExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .padding(.horizontal, 8)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "text.quote")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.accentColor.opacity(0.7))
                        
                        Text(isEditingNotes ? "EDITING NOTES" : "SESSION NOTES")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                            .tracking(0.5)
                        
                        Spacer()
                        
                        if !isEditingNotes {
                            Button(action: {
                                withAnimation {
                                    isEditingNotes = true
                                    editedNotes = session.notes
                                }
                            }) {
                                HStack(spacing: 3) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 8))
                                    Text("Edit")
                                        .font(.system(size: 9, weight: .medium))
                                }
                                .foregroundColor(.accentColor)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    
                    if isEditingNotes {
                        VStack(alignment: .trailing, spacing: 6) {
                            TextEditor(text: $editedNotes)
                                .font(.system(size: 12.5))
                                .foregroundColor(.primary)
                                .lineSpacing(4)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 60, maxHeight: 120)
                                .padding(6)
                                .background(isDark ? Color(red: 0.06, green: 0.06, blue: 0.08) : Color.white)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                                )
                            
                            HStack(spacing: 8) {
                                Button("Cancel") {
                                    withAnimation {
                                        isEditingNotes = false
                                        if session.notes.isEmpty {
                                            isNotesExpanded = false
                                        }
                                    }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                
                                Button("Save") {
                                    manager.updateSessionNotes(id: session.id, notes: editedNotes)
                                    withAnimation {
                                        isEditingNotes = false
                                        if editedNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                            isNotesExpanded = false
                                        }
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 6)
                    } else {
                        Text(session.notes)
                            .font(.system(size: 12.5))
                            .foregroundColor(.primary.opacity(0.85))
                            .lineSpacing(4)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 6)
                    }
                }
                .padding(.bottom, 6)
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
            manager.appTheme == "Glass"
            ? Color.white.opacity(isHovered && (hasNotes || isEditingNotes) ? 0.12 : 0.06)
            : (isDark ? Color(red: 0.10, green: 0.10, blue: 0.12) : Color(red: 0.97, green: 0.97, blue: 0.98)).opacity(isHovered && (hasNotes || isEditingNotes) ? 1.0 : 0.6)
        )
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isNotesExpanded ? Color.accentColor.opacity(0.25) : Color.secondary.opacity(0.08),
                    lineWidth: isNotesExpanded ? 1.5 : 1
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            guard hasNotes else { return }
            guard !isEditingNotes else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                isNotesExpanded.toggle()
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
            if hovering && (hasNotes || isEditingNotes) {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hrs = Int(duration) / 3600
        let mins = (Int(duration) % 3600) / 60
        let secs = Int(duration) % 60
        return String(format: "%02d:%02d:%02d", hrs, mins, secs)
    }
}

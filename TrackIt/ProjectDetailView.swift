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
    @State private var showAddTaskGroupSheet: Bool = false
    @State private var newTaskGroupName: String = ""
    @State private var planningForTaskGroupId: UUID? = nil
    @State private var collapsedGroups: Set<UUID> = []
    
    // For group tags selection/creation in addTaskGroupSheet
    @State private var selectedGroupTagIds: Set<UUID> = []
    @State private var showNewGroupTagField: Bool = false
    @State private var newGroupTagName: String = ""
    @State private var selectedGroupTagColorHex: String = Tag.defaultColors.first ?? "#FF6B6B"
    
    private var groups: [TaskGroup] {
        manager.taskGroups
            .filter { $0.projectRef == project.id }
            .sorted { $0.createdAt < $1.createdAt }
    }
    
    private var ungroupedSessions: [Session] {
        manager.sessions
            .filter { $0.projectRef == project.id && $0.taskGroupRef == nil }
            .sorted { ($0.datePlanned ?? $0.date) < ($1.datePlanned ?? $1.date) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Navigation
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
            
            // Title bar
            HStack(spacing: 12) {
                Circle().fill(Color(hex: project.colorHex)).frame(width: 14, height: 14)
                Text(project.name).font(.title).bold()
                Spacer()
                
                Button(action: { newTaskGroupName = ""; showAddTaskGroupSheet = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "folder.badge.plus")
                        Text("Add Group")
                    }
                }
                .buttonStyle(.bordered)
                
                Button(action: { planningForTaskGroupId = nil; showPlanSessionSheet = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Plan Session")
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            
            Divider()
            
            // Content
            ScrollView {
                if groups.isEmpty && ungroupedSessions.isEmpty {
                    emptyState
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        // Task Groups
                        ForEach(groups) { group in
                            let sessions = sessionsFor(group.id)
                            let collapsed = collapsedGroups.contains(group.id)
                            
                            TaskGroupCard(
                                group: group,
                                sessions: sessions,
                                isCollapsed: collapsed,
                                manager: manager,
                                onToggle: { toggleGroup(group.id) },
                                onPlanSession: {
                                    planningForTaskGroupId = group.id
                                    showPlanSessionSheet = true
                                },
                                onDelete: {
                                    withAnimation { manager.deleteTaskGroup(id: group.id) }
                                }
                            )
                        }
                        
                        // Ungrouped Sessions
                        if !ungroupedSessions.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 8) {
                                    Image(systemName: "tray")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                    Text("Ungrouped")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                    Text("\(ungroupedSessions.count)")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(Color.secondary.opacity(0.12))
                                        .cornerRadius(4)
                                }
                                .padding(.horizontal, 4)
                                
                                VStack(spacing: 6) {
                                    ForEach(ungroupedSessions) { session in
                                        SessionRow(session: session, manager: manager, projectId: project.id)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.trailing, 4)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .sheet(isPresented: $showPlanSessionSheet) {
            ProjectPlanSessionSheet(manager: manager, project: project, taskGroupId: planningForTaskGroupId)
        }
        .sheet(isPresented: $showAddTaskGroupSheet) {
            addTaskGroupSheet
        }
    }
    
    // MARK: - Helpers
    
    private func sessionsFor(_ groupId: UUID) -> [Session] {
        manager.sessions
            .filter { $0.projectRef == project.id && $0.taskGroupRef == groupId }
            .sorted { ($0.datePlanned ?? $0.date) < ($1.datePlanned ?? $1.date) }
    }
    
    private func toggleGroup(_ id: UUID) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if collapsedGroups.contains(id) { collapsedGroups.remove(id) }
            else { collapsedGroups.insert(id) }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            Text("No task groups or sessions yet.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack(spacing: 12) {
                Button(action: { newTaskGroupName = ""; showAddTaskGroupSheet = true }) {
                    HStack(spacing: 4) { Image(systemName: "folder.badge.plus"); Text("Create First Group") }
                }.buttonStyle(.bordered)
                Button(action: { planningForTaskGroupId = nil; showPlanSessionSheet = true }) {
                    HStack(spacing: 4) { Image(systemName: "plus"); Text("Plan a Session") }
                }.buttonStyle(.bordered)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 40)
    }
    
    // MARK: - Add Task Group Sheet
    
    private var addTaskGroupSheet: some View {
        VStack(spacing: 20) {
            Text("Create Task Group").font(.headline)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Group Name").font(.caption).foregroundColor(.secondary)
                        TextField("e.g. Frontend, Backend, Database", text: $newTaskGroupName)
                            .textFieldStyle(.plain)
                            .padding(8)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(NSColor.separatorColor), lineWidth: 1))
                    }
                    
                    // Group Tags Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Group Tags")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                        
                        if !manager.groupTags.isEmpty {
                            FlowLayout(spacing: 6) {
                                ForEach(manager.groupTags) { tag in
                                    TagChip(
                                        tag: tag,
                                        isSelected: selectedGroupTagIds.contains(tag.id),
                                        isCheckable: true
                                    ) {
                                        if selectedGroupTagIds.contains(tag.id) {
                                            selectedGroupTagIds.remove(tag.id)
                                        } else {
                                            selectedGroupTagIds.insert(tag.id)
                                        }
                                    }
                                }
                            }
                        } else if !showNewGroupTagField {
                            Text("No group tags created yet.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        
                        if showNewGroupTagField {
                            VStack(spacing: 10) {
                                TextField("Tag name (e.g. core, experimental)", text: $newGroupTagName)
                                    .textFieldStyle(.plain)
                                    .padding(8)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                                    )
                                
                                HStack(spacing: 6) {
                                    ForEach(Tag.defaultColors, id: \.self) { hex in
                                        Circle()
                                            .fill(Color(hex: hex))
                                            .frame(width: 16, height: 16)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.primary, lineWidth: selectedGroupTagColorHex == hex ? 1.5 : 0)
                                            )
                                            .onTapGesture { selectedGroupTagColorHex = hex }
                                    }
                                }
                                
                                HStack {
                                    Button("Cancel") {
                                        showNewGroupTagField = false
                                        newGroupTagName = ""
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundColor(.secondary)
                                    .font(.footnote)
                                    
                                    Spacer()
                                    
                                    Button("Create & Select") {
                                        let trimmed = newGroupTagName.trimmingCharacters(in: .whitespacesAndNewlines)
                                        if !trimmed.isEmpty {
                                            let newTag = manager.createGroupTag(name: trimmed, colorHex: selectedGroupTagColorHex)
                                            selectedGroupTagIds.insert(newTag.id)
                                            newGroupTagName = ""
                                            showNewGroupTagField = false
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                    .disabled(newGroupTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                }
                            }
                            .padding(10)
                            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
                            .cornerRadius(8)
                            .transition(.slide.combined(with: .opacity))
                        } else {
                            Button(action: {
                                withAnimation { showNewGroupTagField = true }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle")
                                    Text("New Group Tag")
                                }
                                .font(.footnote)
                                .foregroundColor(.accentColor)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 2)
                        }
                    }
                }
            }
            .frame(maxHeight: 280)
            
            HStack {
                Button("Cancel") {
                    showAddTaskGroupSheet = false
                    newTaskGroupName = ""
                    selectedGroupTagIds = []
                    showNewGroupTagField = false
                    newGroupTagName = ""
                }
                .buttonStyle(.bordered)
                Spacer()
                Button("Create Group") {
                    let t = newTaskGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !t.isEmpty {
                        _ = manager.createTaskGroup(name: t, projectRef: project.id, tagRefs: Array(selectedGroupTagIds))
                        newTaskGroupName = ""
                        selectedGroupTagIds = []
                        showNewGroupTagField = false
                        newGroupTagName = ""
                        showAddTaskGroupSheet = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(newTaskGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 400)
    }
}

// MARK: - Task Group Card

struct TaskGroupCard: View {
    let group: TaskGroup
    let sessions: [Session]
    let isCollapsed: Bool
    let manager: SessionFlowManager
    let onToggle: () -> Void
    let onPlanSession: () -> Void
    let onDelete: () -> Void
    
    @State private var isPlanHovered = false
    @State private var isDeleteHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Group Header
            HStack(spacing: 10) {
                Button(action: onToggle) {
                    HStack(spacing: 8) {
                        Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(width: 12)
                        
                        Image(systemName: "folder.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.accentColor)
                        
                        Text(group.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
                .buttonStyle(.plain)
                
                let done = sessions.filter { $0.status == .completed }.count
                Text("\(done)/\(sessions.count)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Color.secondary.opacity(0.12))
                    .cornerRadius(4)
                
                // Group Tags
                let groupTags = (group.tagRefs ?? []).compactMap { tagId in
                    manager.groupTags.first { $0.id == tagId }
                }
                if !groupTags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(groupTags) { tag in
                            TagChip(tag: tag)
                        }
                    }
                }
                
                Spacer()
                
                Button(action: onPlanSession) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 14))
                        .foregroundColor(isPlanHovered ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .onHover { isPlanHovered = $0 }
                .help("Add session to this group")
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(isDeleteHovered ? .red : .secondary.opacity(0.5))
                }
                .buttonStyle(.plain)
                .onHover { isDeleteHovered = $0 }
                .help("Delete group")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.secondary.opacity(0.06))
            .contentShape(Rectangle())
            .onTapGesture { onToggle() }
            
            // Sessions (timeline thread inside card)
            if !isCollapsed {
                if sessions.isEmpty {
                    Text("No sessions — tap ＋ to plan one")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .padding(.leading, 24)
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(sessions.enumerated()), id: \.element.id) { idx, session in
                            let isFirst = idx == 0
                            let isLast = idx == sessions.count - 1
                            let lineColor = sessionLineColor(session)
                            
                            HStack(alignment: .top, spacing: 12) {
                                // Timeline column: vertical line + dot
                                ZStack(alignment: .top) {
                                    // Continuous vertical line
                                    GeometryReader { geo in
                                        VStack(spacing: 0) {
                                            // Line above dot
                                            if isFirst {
                                                Color.clear.frame(width: 2, height: 16)
                                            } else {
                                                Rectangle()
                                                    .fill(lineColor)
                                                    .frame(width: 2, height: 16)
                                            }
                                            // Line below dot
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
                                    
                                    // Status dot on the line
                                    sessionDot(session)
                                        .padding(.top, 10)
                                }
                                .frame(width: 18)
                                
                                // Session content card
                                SessionRow(session: session, manager: manager, showDot: false, projectId: group.projectRef)
                            }
                        }
                    }
                    .padding(.leading, 16)
                    .padding(.top, 6)
                    .padding(.bottom, 4)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.08), lineWidth: 1)
        )
        .cornerRadius(10)
    }
    
    private func sessionLineColor(_ s: Session) -> Color {
        switch s.status {
        case .completed: return .green.opacity(0.35)
        case .running: return .accentColor.opacity(0.35)
        case .planned: return .secondary.opacity(0.18)
        }
    }
    
    @ViewBuilder
    private func sessionDot(_ s: Session) -> some View {
        if s.status == .completed {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 14))
                .background(Circle().fill(Color(NSColor.windowBackgroundColor)))
        } else if s.status == .running {
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
}

// MARK: - Session Row

struct SessionRow: View {
    let session: Session
    let manager: SessionFlowManager
    var showDot: Bool = true
    var projectId: UUID? = nil
    
    @State private var isNotesExpanded: Bool = false
    @State private var isHovered: Bool = false
    @State private var showTagEditor: Bool = false
    @State private var editingTagIds: Set<UUID> = []
    @State private var showNewTagInEditor: Bool = false
    @State private var newTagNameInEditor: String = ""
    @State private var newTagColorInEditor: String = Tag.defaultColors.first ?? "#FF6B6B"
    
    @State private var isEditingNotes: Bool = false
    @State private var editedNotes: String = ""
    
    private var hasNotes: Bool {
        !session.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                // Status dot (hidden when used inside timeline column)
                if showDot {
                    dotView
                }
                
                // Title & subtitle
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(session.title)
                            .fontWeight(.medium)
                            .foregroundColor(session.status == .completed ? .secondary : .primary)
                            .strikethrough(session.status == .completed)
                        
                        if hasNotes {
                            Image(systemName: "note.text")
                                .font(.system(size: 9))
                                .foregroundColor(isNotesExpanded ? .accentColor : .secondary.opacity(0.5))
                        }
                    }
                    
                    HStack(spacing: 6) {
                        Text(session.status == .completed ? "Tracked: \(fmtDuration(session.duration))" : "Target: \(fmtDuration(session.duration))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if session.status == .completed {
                            Text("·")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(session.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
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
                
                // Status badge / Start button
                if session.status == .completed {
                    HStack(spacing: 3) {
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
                    HStack(spacing: 3) {
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
                
                // Move to group
                if let projId = projectId {
                    let groups = manager.taskGroups.filter { $0.projectRef == projId }
                    if !groups.isEmpty {
                        Menu {
                            Section("Move to Group") {
                                Button {
                                    withAnimation { manager.moveSession(id: session.id, toGroupId: nil) }
                                } label: {
                                    if session.taskGroupRef == nil {
                                        Label("Ungrouped", systemImage: "checkmark")
                                    } else {
                                        Text("Ungrouped")
                                    }
                                }
                                
                                ForEach(groups) { group in
                                    Button {
                                        withAnimation { manager.moveSession(id: session.id, toGroupId: group.id) }
                                    } label: {
                                        if session.taskGroupRef == group.id {
                                            Label(group.name, systemImage: "checkmark")
                                        } else {
                                            Text(group.name)
                                        }
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "folder.badge.gearshape")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                        .menuStyle(.borderlessButton)
                        .menuIndicator(.hidden)
                        .fixedSize()
                        .help("Move to another group")
                    }
                }
                
                // Edit tags
                Button(action: {
                    editingTagIds = Set(session.tagRefs ?? [])
                    showNewTagInEditor = false
                    newTagNameInEditor = ""
                    showTagEditor.toggle()
                }) {
                    Image(systemName: "tag")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .buttonStyle(.plain)
                .help("Edit tags")
                .popover(isPresented: $showTagEditor) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Edit Tags")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        if !manager.tags.isEmpty {
                            FlowLayout(spacing: 6) {
                                ForEach(manager.tags) { tag in
                                    TagChip(
                                        tag: tag,
                                        isSelected: editingTagIds.contains(tag.id),
                                        isCheckable: true
                                    ) {
                                        if editingTagIds.contains(tag.id) {
                                            editingTagIds.remove(tag.id)
                                        } else {
                                            editingTagIds.insert(tag.id)
                                        }
                                        manager.updateSessionTags(id: session.id, tagIds: Array(editingTagIds))
                                    }
                                }
                            }
                        } else if !showNewTagInEditor {
                            Text("No tags yet.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                        
                        if showNewTagInEditor {
                            VStack(spacing: 8) {
                                TextField("Tag name", text: $newTagNameInEditor)
                                    .textFieldStyle(.plain)
                                    .padding(6)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(4)
                                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(NSColor.separatorColor), lineWidth: 1))
                                
                                HStack(spacing: 4) {
                                    ForEach(Tag.defaultColors.prefix(5), id: \.self) { hex in
                                        Circle().fill(Color(hex: hex)).frame(width: 14, height: 14)
                                            .overlay(Circle().stroke(Color.primary, lineWidth: newTagColorInEditor == hex ? 1.5 : 0))
                                            .onTapGesture { newTagColorInEditor = hex }
                                    }
                                    Spacer()
                                }
                                
                                HStack {
                                    Button("Cancel") {
                                        showNewTagInEditor = false
                                        newTagNameInEditor = ""
                                    }
                                    .buttonStyle(.plain)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Button("Create & Add") {
                                        let t = newTagNameInEditor.trimmingCharacters(in: .whitespacesAndNewlines)
                                        if !t.isEmpty {
                                            let tag = manager.createTag(name: t, colorHex: newTagColorInEditor)
                                            editingTagIds.insert(tag.id)
                                            manager.updateSessionTags(id: session.id, tagIds: Array(editingTagIds))
                                            newTagNameInEditor = ""
                                            showNewTagInEditor = false
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                    .disabled(newTagNameInEditor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                }
                            }
                        } else {
                            Button(action: { showNewTagInEditor = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle")
                                    Text("New Tag")
                                }
                                .font(.footnote)
                                .foregroundColor(.accentColor)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(14)
                    .frame(width: 240)
                }
                
                // Edit notes
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
                        .font(.system(size: 11))
                        .foregroundColor(isEditingNotes ? .accentColor : .secondary.opacity(0.5))
                }
                .buttonStyle(.plain)
                .help(session.notes.isEmpty ? "Add notes" : "Edit notes")
                
                // Delete
                Button(action: {
                    withAnimation { manager.deleteSession(id: session.id) }
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            
            // Expandable notes
            if isNotesExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    Divider().padding(.horizontal, 8)
                    
                    HStack(spacing: 5) {
                        Image(systemName: "text.quote")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.accentColor.opacity(0.7))
                        Text(isEditingNotes ? "EDITING NOTES" : "NOTES")
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
                                .lineSpacing(3)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 60, maxHeight: 120)
                                .padding(6)
                                .background(Color(NSColor.controlBackgroundColor))
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
                            .lineSpacing(3)
                            .textSelection(.enabled)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 4)
                    }
                }
                .padding(.bottom, 6)
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    )
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor).opacity(isHovered && (hasNotes || isEditingNotes) ? 0.7 : 0.45))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isNotesExpanded ? Color.accentColor.opacity(0.2) :
                        (session.status == .completed ? Color.green.opacity(0.1) : Color.secondary.opacity(0.06)),
                    lineWidth: 1
                )
        )
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture {
            guard hasNotes else { return }
            guard !isEditingNotes else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isNotesExpanded.toggle()
            }
        }
        .onHover { h in
            withAnimation(.easeInOut(duration: 0.12)) { isHovered = h }
            if h && (hasNotes || isEditingNotes) { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
    }
    
    @ViewBuilder
    private var dotView: some View {
        if session.status == .completed {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 13))
        } else if session.status == .running {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 9, height: 9)
                .overlay(Circle().stroke(Color.accentColor.opacity(0.3), lineWidth: 2).scaleEffect(1.3))
        } else {
            Circle()
                .stroke(Color.secondary.opacity(0.35), lineWidth: 1.5)
                .frame(width: 9, height: 9)
        }
    }
    
    private func fmtDuration(_ d: TimeInterval) -> String {
        let t = Int(d)
        if t <= 0 { return "0 sec" }
        let h = t / 3600, m = (t % 3600) / 60, s = t % 60
        var p: [String] = []
        if h > 0 { p.append("\(h)h") }
        if m > 0 { p.append("\(m)min") }
        if s > 0 { p.append("\(s)sec") }
        return p.joined(separator: " ")
    }
}

// MARK: - Plan Session Sheet

struct ProjectPlanSessionSheet: View {
    @Bindable var manager: SessionFlowManager
    let project: Project
    var taskGroupId: UUID? = nil
    
    @State private var title: String = ""
    @State private var durationText: String = "20 min"
    @State private var selectedGroupId: UUID? = nil
    @State private var showNewGroup: Bool = false
    @State private var newGroupName: String = ""
    @State private var selectedTagIds: Set<UUID> = []
    @State private var showNewTagField: Bool = false
    @State private var newTagName: String = ""
    @State private var selectedTagColorHex: String = Tag.defaultColors.first ?? "#FF6B6B"
    
    // For inline group tag creation/selection
    @State private var selectedGroupTagIdsForNewGroup: Set<UUID> = []
    @State private var showNewGroupTagFieldForNewGroup: Bool = false
    @State private var newGroupTagNameForNewGroup: String = ""
    @State private var selectedGroupTagColorHexForNewGroup: String = Tag.defaultColors.first ?? "#FF6B6B"
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Plan a Future Session").font(.headline)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Session Task Name").font(.caption).foregroundColor(.secondary)
                        TextField("e.g. Design Login Screen", text: $title)
                            .textFieldStyle(.plain)
                            .padding(8)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(NSColor.separatorColor), lineWidth: 1))
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Target Duration").font(.caption).foregroundColor(.secondary)
                        TextField("e.g. 45 min, 1h 30m", text: $durationText)
                            .textFieldStyle(.plain)
                            .padding(8)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(NSColor.separatorColor), lineWidth: 1))
                    }
                    
                    // Task Group Picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Task Group").font(.caption).foregroundColor(.secondary)
                        let groups = manager.taskGroups.filter { $0.projectRef == project.id }
                        Picker("", selection: $selectedGroupId) {
                            Text("No Group").tag(nil as UUID?)
                            ForEach(groups) { g in Text(g.name).tag(g.id as UUID?) }
                        }
                        .labelsHidden()
                        
                        if showNewGroup {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    TextField("New group name", text: $newGroupName)
                                        .textFieldStyle(.plain)
                                        .padding(6)
                                        .background(Color(NSColor.controlBackgroundColor))
                                        .cornerRadius(4)
                                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(NSColor.separatorColor), lineWidth: 1))
                                    Button("Add") {
                                        let t = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
                                        if !t.isEmpty {
                                            let g = manager.createTaskGroup(
                                                name: t,
                                                projectRef: project.id,
                                                tagRefs: Array(selectedGroupTagIdsForNewGroup)
                                            )
                                            selectedGroupId = g.id
                                            newGroupName = ""
                                            selectedGroupTagIdsForNewGroup = []
                                            showNewGroup = false
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                    .disabled(newGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                    Button("Cancel") {
                                        showNewGroup = false
                                        newGroupName = ""
                                        selectedGroupTagIdsForNewGroup = []
                                        showNewGroupTagFieldForNewGroup = false
                                        newGroupTagNameForNewGroup = ""
                                    }
                                    .buttonStyle(.plain).font(.caption).foregroundColor(.secondary)
                                }
                                
                                // Group Tags inside inline creator
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("New Group Tags").font(.system(size: 10)).foregroundColor(.secondary)
                                    if !manager.groupTags.isEmpty {
                                        FlowLayout(spacing: 4) {
                                            ForEach(manager.groupTags) { tag in
                                                TagChip(
                                                    tag: tag,
                                                    isSelected: selectedGroupTagIdsForNewGroup.contains(tag.id),
                                                    isCheckable: true
                                                ) {
                                                    if selectedGroupTagIdsForNewGroup.contains(tag.id) {
                                                        selectedGroupTagIdsForNewGroup.remove(tag.id)
                                                    } else {
                                                        selectedGroupTagIdsForNewGroup.insert(tag.id)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    
                                    if showNewGroupTagFieldForNewGroup {
                                        HStack {
                                            TextField("Tag name", text: $newGroupTagNameForNewGroup)
                                                .textFieldStyle(.plain)
                                                .padding(4)
                                                .background(Color(NSColor.controlBackgroundColor))
                                                .cornerRadius(4)
                                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(NSColor.separatorColor), lineWidth: 1))
                                            
                                            HStack(spacing: 3) {
                                                ForEach(Tag.defaultColors.prefix(5), id: \.self) { hex in
                                                    Circle().fill(Color(hex: hex)).frame(width: 12, height: 12)
                                                        .overlay(Circle().stroke(Color.primary, lineWidth: selectedGroupTagColorHexForNewGroup == hex ? 1.5 : 0))
                                                        .onTapGesture { selectedGroupTagColorHexForNewGroup = hex }
                                                }
                                            }
                                            
                                            Button("Create") {
                                                let trimmed = newGroupTagNameForNewGroup.trimmingCharacters(in: .whitespacesAndNewlines)
                                                if !trimmed.isEmpty {
                                                    let tag = manager.createGroupTag(name: trimmed, colorHex: selectedGroupTagColorHexForNewGroup)
                                                    selectedGroupTagIdsForNewGroup.insert(tag.id)
                                                    newGroupTagNameForNewGroup = ""
                                                    showNewGroupTagFieldForNewGroup = false
                                                }
                                            }
                                            .buttonStyle(.borderedProminent)
                                            .controlSize(.small)
                                            .disabled(newGroupTagNameForNewGroup.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                            
                                            Button("X") {
                                                showNewGroupTagFieldForNewGroup = false
                                                newGroupTagNameForNewGroup = ""
                                            }
                                            .buttonStyle(.plain).font(.caption).foregroundColor(.secondary)
                                        }
                                    } else {
                                        Button(action: { showNewGroupTagFieldForNewGroup = true }) {
                                            HStack(spacing: 2) {
                                                Image(systemName: "plus.circle")
                                                Text("New Tag")
                                            }
                                            .font(.system(size: 10))
                                            .foregroundColor(.accentColor)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(6)
                                .background(Color.secondary.opacity(0.04))
                                .cornerRadius(6)
                            }
                        } else {
                            Button(action: { showNewGroup = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle")
                                    Text("New Group")
                                }
                                .font(.footnote)
                                .foregroundColor(.accentColor)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Tags Section
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Session Tags").font(.caption).foregroundColor(.secondary)
                        
                        if !manager.tags.isEmpty {
                            FlowLayout(spacing: 6) {
                                ForEach(manager.tags) { tag in
                                    TagChip(
                                        tag: tag,
                                        isSelected: selectedTagIds.contains(tag.id),
                                        isCheckable: true
                                    ) {
                                        if selectedTagIds.contains(tag.id) {
                                            selectedTagIds.remove(tag.id)
                                        } else {
                                            selectedTagIds.insert(tag.id)
                                        }
                                    }
                                }
                            }
                        }
                        
                        if showNewTagField {
                            HStack {
                                TextField("Tag name", text: $newTagName)
                                    .textFieldStyle(.plain)
                                    .padding(6)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(4)
                                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(NSColor.separatorColor), lineWidth: 1))
                                
                                HStack(spacing: 4) {
                                    ForEach(Tag.defaultColors.prefix(5), id: \.self) { hex in
                                        Circle().fill(Color(hex: hex)).frame(width: 14, height: 14)
                                            .overlay(Circle().stroke(Color.primary, lineWidth: selectedTagColorHex == hex ? 1.5 : 0))
                                            .onTapGesture { selectedTagColorHex = hex }
                                    }
                                }
                                
                                Button("Add") {
                                    let t = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if !t.isEmpty {
                                        let tag = manager.createTag(name: t, colorHex: selectedTagColorHex)
                                        selectedTagIds.insert(tag.id)
                                        newTagName = ""
                                        showNewTagField = false
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                                .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                
                                Button("Cancel") { showNewTagField = false; newTagName = "" }
                                    .buttonStyle(.plain).font(.caption).foregroundColor(.secondary)
                            }
                        } else {
                            Button(action: { showNewTagField = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle")
                                    Text("New Tag")
                                }
                                .font(.footnote)
                                .foregroundColor(.accentColor)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .frame(maxHeight: 320)
            
            HStack {
                Button("Cancel") { dismiss() }.buttonStyle(.bordered)
                Spacer()
                Button("Save Plan") {
                    let dur = manager.parseDuration(durationText)?.duration ?? 1800
                    manager.planSession(
                        title: title.isEmpty ? "Planned Work Block" : title,
                        duration: dur,
                        projectId: project.id,
                        taskGroupId: selectedGroupId,
                        tagIds: Array(selectedTagIds)
                    )
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 400)
        .onAppear { selectedGroupId = taskGroupId }
    }
}

//
//  SessionSaveSheet.swift
//  TrackIt
//
//  Created by Antigravity on 6/3/26.
//

import SwiftUI

struct SessionSaveSheet: View {
    @Bindable var manager: SessionFlowManager
    let duration: TimeInterval
    
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
    
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var selectedProjectId: UUID? = nil
    @State private var selectedTaskGroupId: UUID? = nil
    @State private var selectedTagIds: Set<UUID> = []
    
    // For creating a new project inline
    @State private var showNewProjectField: Bool = false
    @State private var newProjectName: String = ""
    @State private var selectedColorHex: String = Project.defaultColors.first ?? "#4A90E2"
    
    // For creating a new task group inline (when new project created)
    @State private var justCreatedNewProject: Bool = false
    @State private var showNewGroupField: Bool = false
    @State private var isEditingExistingGroup: Bool = false
    @State private var editingGroupId: UUID? = nil
    @State private var newGroupName: String = ""
    @State private var selectedGroupTagIds: Set<UUID> = []
    @State private var showNewGroupTagField: Bool = false
    @State private var newGroupTagName: String = ""
    @State private var selectedGroupTagColorHex: String = Tag.defaultColors.first ?? "#FF6B6B"
    
    // For creating a new tag inline
    @State private var showNewTagField: Bool = false
    @State private var newTagName: String = ""
    @State private var selectedTagColorHex: String = Tag.defaultColors.first ?? "#FF6B6B"
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Complete Session")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text(formatDuration(duration))
                    .font(.system(.title2, design: .monospaced))
                    .bold()
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(isDark ? Color(red: 0.10, green: 0.10, blue: 0.12) : Color(white: 0.98))
            
            Divider()
            
            VStack(spacing: 20) {
                ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Session Title Input
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Session Title")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                        
                        TextField("e.g. Database Design, Fixed auth bug", text: $title)
                            .textFieldStyle(.plain)
                            .padding(10)
                            .background((isDark ? Color(red: 0.10, green: 0.10, blue: 0.12) : Color(red: 0.97, green: 0.97, blue: 0.98)))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                            )
                    }
                    
                    // Project Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Project")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                        
                        if !manager.projects.isEmpty {
                            FlowLayout(spacing: 8) {
                                // Standalone Session Option
                                ProjectBadge(
                                    name: "Standalone",
                                    color: .gray,
                                    isSelected: selectedProjectId == nil
                                ) {
                                    selectedProjectId = nil
                                    justCreatedNewProject = false
                                    selectedTaskGroupId = nil
                                    showNewGroupField = false
                                    selectedGroupTagIds = []
                                }
                                
                                // Project Badges
                                ForEach(manager.projects) { proj in
                                    ProjectBadge(
                                        name: proj.name,
                                        color: Color(hex: proj.colorHex),
                                        isSelected: selectedProjectId == proj.id
                                    ) {
                                        selectedProjectId = proj.id
                                        justCreatedNewProject = false
                                        selectedTaskGroupId = nil
                                        showNewGroupField = false
                                        selectedGroupTagIds = []
                                    }
                                }
                            }
                        } else {
                            Text("No projects created yet.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        
                        // Inline New Project Creator
                        if showNewProjectField {
                            VStack(spacing: 12) {
                                TextField("New Project Name", text: $newProjectName)
                                    .textFieldStyle(.plain)
                                    .padding(8)
                                    .background((isDark ? Color(red: 0.10, green: 0.10, blue: 0.12) : Color(red: 0.97, green: 0.97, blue: 0.98)))
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                                    )
                                
                                // Color Selector
                                HStack(spacing: 8) {
                                    ForEach(Project.defaultColors, id: \.self) { hex in
                                        Circle()
                                            .fill(Color(hex: hex))
                                            .frame(width: 18, height: 18)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.primary, lineWidth: selectedColorHex == hex ? 1.5 : 0)
                                            )
                                            .onTapGesture {
                                                selectedColorHex = hex
                                            }
                                    }
                                }
                                
                                HStack {
                                    Button("Cancel Project") {
                                        showNewProjectField = false
                                        newProjectName = ""
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundColor(.secondary)
                                    .font(.footnote)
                                    
                                    Spacer()
                                    
                                    Button("Create & Select") {
                                        if !newProjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                            let newProj = manager.createProject(name: newProjectName, colorHex: selectedColorHex)
                                            selectedProjectId = newProj.id
                                            newProjectName = ""
                                            showNewProjectField = false
                                            justCreatedNewProject = true
                                            selectedTaskGroupId = nil
                                            showNewGroupField = false
                                            selectedGroupTagIds = []
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                }
                            }
                            .padding(10)
                            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
                            .cornerRadius(8)
                            .transition(.slide.combined(with: .opacity))
                        } else {
                            Button(action: {
                                withAnimation {
                                    showNewProjectField = true
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle")
                                    Text("New Project")
                                }
                                .font(.footnote)
                                .foregroundColor(.accentColor)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 4)
                        }
                    }
                    
                    // Task Group Picker (shown when a project is selected)
                    if selectedProjectId != nil {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Task Group")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontWeight(.medium)
                            
                            let groups = manager.taskGroups.filter { $0.projectRef == selectedProjectId }
                            
                            // Task Group Selector & Inline Creator
                            if showNewGroupField {
                                    VStack(spacing: 12) {
                                        TextField(isEditingExistingGroup ? "Edit Group Name" : "New Group Name (e.g. Frontend, Backend)", text: $newGroupName)
                                            .textFieldStyle(.plain)
                                            .padding(8)
                                            .background((isDark ? Color(red: 0.10, green: 0.10, blue: 0.12) : Color(red: 0.97, green: 0.97, blue: 0.98)))
                                            .cornerRadius(6)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                                            )
                                        
                                        // Group Tags Section
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Group Tags")
                                                .font(.system(size: 10))
                                                .foregroundColor(.secondary)
                                            
                                            if !manager.groupTags.isEmpty {
                                                FlowLayout(spacing: 4) {
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
                                            }
                                            
                                            if showNewGroupTagField {
                                                VStack(spacing: 8) {
                                                    TextField("Tag name (e.g. core, experimental)", text: $newGroupTagName)
                                                        .textFieldStyle(.plain)
                                                        .padding(6)
                                                        .background((isDark ? Color(red: 0.10, green: 0.10, blue: 0.12) : Color(red: 0.97, green: 0.97, blue: 0.98)))
                                                        .cornerRadius(4)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 4)
                                                                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                                                        )
                                                    
                                                    HStack(spacing: 4) {
                                                        ForEach(Tag.defaultColors.prefix(5), id: \.self) { hex in
                                                            Circle().fill(Color(hex: hex)).frame(width: 14, height: 14)
                                                                .overlay(
                                                                    Circle().stroke(Color.primary, lineWidth: selectedGroupTagColorHex == hex ? 1.5 : 0)
                                                                )
                                                                .onTapGesture { selectedGroupTagColorHex = hex }
                                                        }
                                                        Spacer()
                                                    }
                                                    
                                                    HStack {
                                                        Button("Cancel") {
                                                            showNewGroupTagField = false
                                                            newGroupTagName = ""
                                                        }
                                                        .buttonStyle(.plain)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                        
                                                        Spacer()
                                                        
                                                        Button("Create & Add") {
                                                            let t = newGroupTagName.trimmingCharacters(in: .whitespacesAndNewlines)
                                                            if !t.isEmpty {
                                                                let tag = manager.createGroupTag(name: t, colorHex: selectedGroupTagColorHex)
                                                                selectedGroupTagIds.insert(tag.id)
                                                                newGroupTagName = ""
                                                                showNewGroupTagField = false
                                                            }
                                                        }
                                                        .buttonStyle(.borderedProminent)
                                                        .controlSize(.small)
                                                        .disabled(newGroupTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                                    }
                                                }
                                            } else {
                                                Button(action: { showNewGroupTagField = true }) {
                                                    HStack(spacing: 4) {
                                                        Image(systemName: "plus.circle")
                                                        Text("New Group Tag")
                                                    }
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.accentColor)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        .padding(8)
                                        .background(Color.secondary.opacity(0.04))
                                        .cornerRadius(6)
                                        
                                        HStack {
                                            Button("Cancel") {
                                                showNewGroupField = false
                                                newGroupName = ""
                                                selectedGroupTagIds = []
                                                showNewGroupTagField = false
                                                newGroupTagName = ""
                                                isEditingExistingGroup = false
                                                editingGroupId = nil
                                            }
                                            .buttonStyle(.plain)
                                            .foregroundColor(.secondary)
                                            .font(.footnote)
                                            
                                            Spacer()
                                            
                                            Button(isEditingExistingGroup ? "Save Changes" : "Create & Select") {
                                                let t = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
                                                if !t.isEmpty, let projId = selectedProjectId {
                                                    if isEditingExistingGroup, let editingId = editingGroupId {
                                                        manager.updateTaskGroup(
                                                            id: editingId,
                                                            name: t,
                                                            tagRefs: Array(selectedGroupTagIds)
                                                        )
                                                        selectedTaskGroupId = editingId
                                                    } else {
                                                        let newGroup = manager.createTaskGroup(
                                                            name: t,
                                                            projectRef: projId,
                                                            tagRefs: Array(selectedGroupTagIds)
                                                        )
                                                        selectedTaskGroupId = newGroup.id
                                                    }
                                                    newGroupName = ""
                                                    selectedGroupTagIds = []
                                                    showNewGroupField = false
                                                    showNewGroupTagField = false
                                                    newGroupTagName = ""
                                                    isEditingExistingGroup = false
                                                    editingGroupId = nil
                                                }
                                            }
                                            .buttonStyle(.borderedProminent)
                                            .controlSize(.small)
                                            .disabled(newGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                        }
                                    }
                                    .padding(10)
                                    .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
                                    .cornerRadius(8)
                                    .transition(.slide.combined(with: .opacity))
                            } else {
                                HStack {
                                    if !groups.isEmpty {
                                        Picker("", selection: $selectedTaskGroupId) {
                                            Text("Ungrouped").tag(nil as UUID?)
                                            ForEach(groups) { group in
                                                Text(group.name).tag(group.id as UUID?)
                                            }
                                        }
                                        .labelsHidden()
                                    } else {
                                        Text("No task groups in this project.")
                                            .font(.footnote)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    if selectedTaskGroupId != nil {
                                        Button(action: {
                                            if let groupId = selectedTaskGroupId, let group = groups.first(where: { $0.id == groupId }) {
                                                newGroupName = group.name
                                                selectedGroupTagIds = Set(group.tagRefs ?? [])
                                                editingGroupId = group.id
                                                isEditingExistingGroup = true
                                                withAnimation { showNewGroupField = true }
                                            }
                                        }) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "pencil.circle")
                                                Text("Edit Group")
                                            }
                                            .font(.footnote)
                                            .foregroundColor(.accentColor)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    
                                    Button(action: {
                                        isEditingExistingGroup = false
                                        editingGroupId = nil
                                        newGroupName = ""
                                        selectedGroupTagIds = []
                                        withAnimation { showNewGroupField = true }
                                    }) {
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
                        }
                    }
                    
                    // Tags Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Session Tag")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                        
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
                        } else if !showNewTagField {
                            Text("No session tags created yet.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        
                        if showNewTagField {
                            VStack(spacing: 10) {
                                TextField("Tag name (e.g. database, UI, bug fix)", text: $newTagName)
                                    .textFieldStyle(.plain)
                                    .padding(8)
                                    .background((isDark ? Color(red: 0.10, green: 0.10, blue: 0.12) : Color(red: 0.97, green: 0.97, blue: 0.98)))
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
                                                    .stroke(Color.primary, lineWidth: selectedTagColorHex == hex ? 1.5 : 0)
                                            )
                                            .onTapGesture { selectedTagColorHex = hex }
                                    }
                                }
                                
                                HStack {
                                    Button("Cancel") {
                                        showNewTagField = false
                                        newTagName = ""
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundColor(.secondary)
                                    .font(.footnote)
                                    
                                    Spacer()
                                    
                                    Button("Create & Select") {
                                        let trimmed = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
                                        if !trimmed.isEmpty {
                                            let newTag = manager.createTag(name: trimmed, colorHex: selectedTagColorHex)
                                            selectedTagIds.insert(newTag.id)
                                            newTagName = ""
                                            showNewTagField = false
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                    .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                }
                            }
                            .padding(10)
                            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
                            .cornerRadius(8)
                            .transition(.slide.combined(with: .opacity))
                        } else {
                            Button(action: {
                                withAnimation { showNewTagField = true }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle")
                                    Text("New Session Tag")
                                }
                                .font(.footnote)
                                .foregroundColor(.accentColor)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 2)
                        }
                    }
                    
                    // Notes Input
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                        
                        TextEditor(text: $notes)
                            .font(.system(.body))
                            .padding(8)
                            .frame(minHeight: 100, maxHeight: 150)
                            .background((isDark ? Color(red: 0.10, green: 0.10, blue: 0.12) : Color(red: 0.97, green: 0.97, blue: 0.98)))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                            )
                    }
                }
            }
            .frame(maxHeight: 400)
            
            // Footer Action Buttons
            HStack(spacing: 12) {
                Button("Discard") {
                    manager.resetTimer()
                    SaveSheetWindowManager.shared.closeSaveSheet()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .keyboardShortcut(.escape, modifiers: [])
                
                Spacer()
                
                Button("Save Session") {
                    manager.saveSession(
                        title: title,
                        notes: notes,
                        projectId: selectedProjectId,
                        taskGroupId: selectedTaskGroupId,
                        tagIds: Array(selectedTagIds),
                        duration: duration
                    )
                    manager.activeNotes = ""
                    
                    let navProjectId = selectedProjectId
                    
                    SaveSheetWindowManager.shared.closeSaveSheet()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        // Navigate to the project where the session was saved, or dashboard for standalone
                        if let projectId = navProjectId {
                            manager.activeWorkspaceTab = .projects
                            manager.activeWorkspaceProjectId = projectId
                        } else {
                            manager.activeWorkspaceTab = .dashboard
                            manager.activeWorkspaceProjectId = nil
                        }
                        
                        // Switch to workspace view
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                            manager.currentView = .workspace
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.return, modifiers: [])
            }
        }
        .padding(24)
        }
        .frame(maxWidth: .infinity)
        .background(isDark ? Color(red: 0.06, green: 0.06, blue: 0.08) : Color.white)
        .preferredColorScheme(manager.appTheme == "Dark" ? .dark : (manager.appTheme == "Light" ? .light : nil))
        .onAppear {
            if let activeId = manager.activeSessionId,
               let activeSession = manager.sessions.first(where: { $0.id == activeId }) {
                title = activeSession.title
                selectedProjectId = activeSession.projectRef
                selectedTaskGroupId = activeSession.taskGroupRef
                notes = activeSession.notes
                selectedTagIds = Set(activeSession.tagRefs ?? [])
            } else {
                notes = manager.activeNotes
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


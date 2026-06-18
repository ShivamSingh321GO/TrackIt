//
//  WorkspaceView.swift
//  TrackIt
//
//  Created by Antigravity on 6/3/26.
//

import SwiftUI

struct WorkspaceView: View {
    @Bindable var manager: SessionFlowManager
    
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
    
    @State private var workspaceTab: WorkspaceTab = .dashboard
    @State private var searchText: String = ""
    @State private var searchMode: SearchMode = .sessions
    @State private var selectedFilterTagIds: Set<UUID> = []
    @State private var selectedFilterGroupTagIds: Set<UUID> = []
    @State private var selectedProject: Project? = nil
    
    // Inline creation for planned session
    @State private var showAddPlannedSessionSheet: Bool = false
    @State private var plannedSessionTitle: String = ""
    @State private var plannedSessionDurationText: String = "20 min"
    @State private var plannedSessionProjectId: UUID? = nil
    @State private var plannedSessionTaskGroupId: UUID? = nil
    @State private var isCreatingNewProjectInSheet: Bool = false
    @State private var newProjectNameInSheet: String = ""
    @State private var newProjectColorInSheet: String = Project.defaultColors.first ?? "#4A90E2"
    @State private var isCreatingNewGroup: Bool = false
    @State private var isEditingExistingGroupInSheet: Bool = false
    @State private var editingGroupIdInSheet: UUID? = nil
    @State private var newGroupNameInSheet: String = ""
    @State private var plannedSessionGroupTagIds: Set<UUID> = []
    @State private var showNewGroupTagInSheet: Bool = false
    @State private var newGroupTagNameInSheet: String = ""
    @State private var newGroupTagColorInSheet: String = Tag.defaultColors.first ?? "#FF6B6B"
    @State private var plannedSessionTagIds: Set<UUID> = []
    @State private var showNewTagInSheet: Bool = false
    @State private var newTagNameInSheet: String = ""
    @State private var newTagColorInSheet: String = Tag.defaultColors.first ?? "#FF6B6B"
    
    // Project creation state
    @State private var showAddProjectSheet: Bool = false
    @State private var newProjectName: String = ""
    @State private var newProjectColorHex: String = Project.defaultColors.first ?? "#4A90E2"
    
    enum WorkspaceTab {
        case dashboard
        case search
        case projects
    }
    
    enum SearchMode {
        case sessions
        case groups
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 6) {
                // Workspace Header
                HStack {
                    Image(systemName: "square.grid.2x2.fill")
                        .foregroundColor(.accentColor)
                    Text("Workspace")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 16)
                
                Divider()
                    .padding(.bottom, 8)
                
                // Sidebar Buttons
                SidebarButton(title: "Dashboard", icon: "gauge.with.needle", isSelected: workspaceTab == .dashboard) {
                    selectedProject = nil
                    workspaceTab = .dashboard
                }
                
                SidebarButton(title: "Projects", icon: "folder", isSelected: workspaceTab == .projects) {
                    selectedProject = nil
                    workspaceTab = .projects
                }
                
                SidebarButton(title: "Search & Insights", icon: "magnifyingglass", isSelected: workspaceTab == .search) {
                    selectedProject = nil
                    workspaceTab = .search
                }
                

                
                Spacer()
                
                // Back to Timer
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        manager.currentView = .timer
                    }
                }) {
                    HStack {
                        Image(systemName: "timer")
                        Text("Open Timer")
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                            .imageScale(.small)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(8)
                    .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                .padding(12)
            }
            .frame(width: 200)
            .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow))
            
            Divider()
            
            // Main Content Area
            VStack(spacing: 0) {
                switch workspaceTab {
                case .dashboard:
                    dashboardTab
                case .search:
                    searchTab
                case .projects:
                    if let project = selectedProject {
                        ProjectDetailView(project: project, manager: manager) {
                            selectedProject = nil
                        }
                    } else {
                        projectsTab
                    }

                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.windowBackgroundColor).allowsHitTesting(false))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(
            Rectangle()
                .fill(isDark ? Color.clear : Color.black)
                .frame(height: 1),
            alignment: .top
        )
        .sheet(isPresented: $showAddPlannedSessionSheet) {
            addPlannedSessionSheet
        }
        .sheet(isPresented: $showAddProjectSheet) {
            addProjectSheet
        }
    }
    
    // MARK: - Dashboard Tab (Overview + Planned + History)
    private var dashboardTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Active Overview")
                            .font(.title2)
                            .bold()
                        Text("Manage planned tasks and review recent activity.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    Button(action: { showAddPlannedSessionSheet = true }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Plan Session")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                // Planned Sessions Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Planned Sessions")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    let planned = manager.sessions.filter { $0.status == .planned }
                    if planned.isEmpty {
                        VStack(spacing: 12) {
                            Text("No sessions planned yet.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Button("Plan Your First Session") {
                                showAddPlannedSessionSheet = true
                            }
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                        .background(Color.secondary.opacity(0.04))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                        )
                    } else {
                        VStack(spacing: 10) {
                            ForEach(planned) { session in
                                PlannedSessionRow(session: session, manager: manager)
                            }
                        }
                    }
                }
                
                // Recent Sessions Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Sessions")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    let completed = manager.sessions.filter { $0.status == .completed }
                    if completed.isEmpty {
                        Text("No completed sessions yet. Start the timer to complete a session!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 20)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(completed.prefix(5)) { session in
                                CompletedSessionRow(session: session, manager: manager)
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
    }
    
    // MARK: - Search & Insights Tab
    private var searchTab: some View {
        VStack(spacing: 0) {
            // Search Controls Header
            VStack(spacing: 14) {
                // Search Mode Selector
                Picker("Search Mode", selection: $searchMode) {
                    Label("Sessions", systemImage: "clock").tag(SearchMode.sessions)
                    Label("Groups", systemImage: "folder").tag(SearchMode.groups)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 280)
                .onChange(of: searchMode) { _, _ in
                    selectedFilterTagIds = []
                    selectedFilterGroupTagIds = []
                }
                
                // Search Input Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField(
                        searchMode == .sessions
                            ? "Search sessions by title, notes, project..."
                            : "Search groups by name, project...",
                        text: $searchText
                    )
                    .textFieldStyle(.plain)
                    .font(.body)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                // Tag Filters for Sessions
                if searchMode == .sessions && !manager.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Filter by Tags")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontWeight(.medium)
                            if !selectedFilterTagIds.isEmpty {
                                Button(action: { selectedFilterTagIds = [] }) {
                                    Text("Clear")
                                        .font(.caption2)
                                        .foregroundColor(.accentColor)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        FlowLayout(spacing: 6) {
                            ForEach(manager.tags) { tag in
                                TagChip(
                                    tag: tag,
                                    isSelected: selectedFilterTagIds.contains(tag.id),
                                    isCheckable: true
                                ) {
                                    if selectedFilterTagIds.contains(tag.id) {
                                        selectedFilterTagIds.remove(tag.id)
                                    } else {
                                        selectedFilterTagIds.insert(tag.id)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Tag Filters for Groups
                if searchMode == .groups && !manager.groupTags.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Filter by Group Tags")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontWeight(.medium)
                            if !selectedFilterGroupTagIds.isEmpty {
                                Button(action: { selectedFilterGroupTagIds = [] }) {
                                    Text("Clear")
                                        .font(.caption2)
                                        .foregroundColor(.accentColor)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        FlowLayout(spacing: 6) {
                            ForEach(manager.groupTags) { tag in
                                TagChip(
                                    tag: tag,
                                    isSelected: selectedFilterGroupTagIds.contains(tag.id),
                                    isCheckable: true
                                ) {
                                    if selectedFilterGroupTagIds.contains(tag.id) {
                                        selectedFilterGroupTagIds.remove(tag.id)
                                    } else {
                                        selectedFilterGroupTagIds.insert(tag.id)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(24)
            
            Divider()
            
            // Results Area
            let hasActiveSearch = !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || (searchMode == .sessions && !selectedFilterTagIds.isEmpty)
                || (searchMode == .groups && !selectedFilterGroupTagIds.isEmpty)
            
            if !hasActiveSearch {
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 32))
                        .foregroundColor(.accentColor.opacity(0.7))
                    Text("Search & Insights")
                        .font(.headline)
                    Text(searchMode == .sessions
                         ? "Search sessions by keyword or filter by tags to view duration analytics."
                         : "Search task groups by keyword or filter by group tags.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 340)
                }
                .frame(maxHeight: .infinity)
            } else if searchMode == .sessions {
                sessionSearchResults
            } else {
                groupSearchResults
            }
        }
    }
    
    // MARK: - Session Search Results
    private var sessionSearchResults: some View {
        ScrollView {
            let results = searchSessions()
            let completed = results.filter { $0.status == .completed }
            
            VStack(alignment: .leading, spacing: 20) {
                // Duration Stats Panel
                if !completed.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 6) {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(.accentColor)
                            Text("Session Duration Stats")
                                .font(.headline)
                            Text("\(completed.count) completed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        let durations = completed.map { $0.duration }
                        let longest = durations.max() ?? 0
                        let shortest = durations.min() ?? 0
                        let average = durations.reduce(0, +) / Double(durations.count)
                        let total = durations.reduce(0, +)
                        
                        HStack(spacing: 14) {
                            StatCard(title: "Longest", value: formatHoursMins(longest), icon: "arrow.up.circle.fill", color: .orange)
                            StatCard(title: "Shortest", value: formatHoursMins(shortest), icon: "arrow.down.circle.fill", color: .green)
                            StatCard(title: "Average", value: formatHoursMins(average), icon: "equal.circle.fill", color: .accentColor)
                            StatCard(title: "Total Time", value: formatHoursMins(total), icon: "clock.fill", color: .purple)
                        }
                    }
                    .padding(16)
                    .background(Color.accentColor.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.accentColor.opacity(0.15), lineWidth: 1)
                    )
                }
                
                // Matching Sessions List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Matching Sessions (\(results.count))")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if results.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("No matching sessions found.")
                                .foregroundColor(.secondary)
                                .italic()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(results) { session in
                                CompletedSessionRow(session: session, manager: manager)
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
    }
    
    // MARK: - Group Search Results
    private var groupSearchResults: some View {
        ScrollView {
            let results = searchGroups()
            
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Matching Groups (\(results.count))")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if results.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "folder.badge.questionmark")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("No matching groups found.")
                                .foregroundColor(.secondary)
                                .italic()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(results) { group in
                                MatchingGroupRow(group: group, manager: manager, onSelect: {
                                    if let proj = manager.projects.first(where: { $0.id == group.projectRef }) {
                                        selectedProject = proj
                                        workspaceTab = .projects
                                    }
                                })
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
    }
    
    // MARK: - Projects Tab
    private var projectsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Projects")
                            .font(.title2)
                            .bold()
                        Text("Create and review projects containing work blocks.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    Button(action: { showAddProjectSheet = true }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("New Project")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                // Project Cards Grid
                if manager.projects.isEmpty {
                    Text("No projects configured.")
                        .foregroundColor(.secondary)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 280))], spacing: 16) {
                        ForEach(manager.projects) { project in
                            ProjectCard(project: project, manager: manager, onSelect: {
                                selectedProject = project
                            }, onPlanSession: {
                                plannedSessionProjectId = project.id
                                plannedSessionTitle = ""
                                plannedSessionDurationText = "20 min"
                                showAddPlannedSessionSheet = true
                            })
                        }
                    }
                }
            }
            .padding(24)
        }
    }
    

    
    // MARK: - Helpers & Data Computations
    
    private func searchSessions() -> [Session] {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        var results = manager.sessions
        
        // Filter by keyword if provided
        if !keyword.isEmpty {
            results = results.filter { session in
                let titleMatch = session.title.lowercased().contains(keyword)
                let notesMatch = session.notes.lowercased().contains(keyword)
                
                var projectMatch = false
                if let projId = session.projectRef,
                   let proj = manager.projects.first(where: { $0.id == projId }) {
                    projectMatch = proj.name.lowercased().contains(keyword)
                }
                
                // Session Tags Match
                var tagMatch = false
                let sessionTags = (session.tagRefs ?? []).compactMap { tagId in
                    manager.tags.first { $0.id == tagId }
                }
                for tag in sessionTags {
                    if tag.name.lowercased().contains(keyword) {
                        tagMatch = true
                        break
                    }
                }
                
                // Task Group Match
                var groupMatch = false
                var groupTagMatch = false
                if let groupId = session.taskGroupRef,
                   let group = manager.taskGroups.first(where: { $0.id == groupId }) {
                    groupMatch = group.name.lowercased().contains(keyword)
                    
                    let groupTags = (group.tagRefs ?? []).compactMap { tagId in
                        manager.groupTags.first { $0.id == tagId }
                    }
                    for tag in groupTags {
                        if tag.name.lowercased().contains(keyword) {
                            groupTagMatch = true
                            break
                        }
                    }
                }
                
                return titleMatch || notesMatch || projectMatch || tagMatch || groupMatch || groupTagMatch
            }
        }
        
        // Filter by selected tags (OR: session must have at least one selected tag)
        if !selectedFilterTagIds.isEmpty {
            results = results.filter { session in
                let sessionTagIds = Set(session.tagRefs ?? [])
                return !selectedFilterTagIds.isDisjoint(with: sessionTagIds)
            }
        }
        
        return results
    }
    
    private func searchGroups() -> [TaskGroup] {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        var results = manager.taskGroups
        
        // Filter by keyword if provided
        if !keyword.isEmpty {
            results = results.filter { group in
                let nameMatch = group.name.lowercased().contains(keyword)
                
                var projectMatch = false
                if let proj = manager.projects.first(where: { $0.id == group.projectRef }) {
                    projectMatch = proj.name.lowercased().contains(keyword)
                }
                
                var tagMatch = false
                let groupTags = (group.tagRefs ?? []).compactMap { tagId in
                    manager.groupTags.first { $0.id == tagId }
                }
                for tag in groupTags {
                    if tag.name.lowercased().contains(keyword) {
                        tagMatch = true
                        break
                    }
                }
                
                return nameMatch || projectMatch || tagMatch
            }
        }
        
        // Filter by selected group tags (OR: group must have at least one selected tag)
        if !selectedFilterGroupTagIds.isEmpty {
            results = results.filter { group in
                let groupTagIds = Set(group.tagRefs ?? [])
                return !selectedFilterGroupTagIds.isDisjoint(with: groupTagIds)
            }
        }
        
        return results
    }
    

    
    private func formatHoursMins(_ seconds: TimeInterval) -> String {
        let hrs = Int(seconds) / 3600
        let mins = (Int(seconds) % 3600) / 60
        if hrs > 0 {
            return "\(hrs)h \(mins)m"
        } else {
            return "\(mins)m"
        }
    }
    
    // MARK: - Add Planned Session Sheet
    private var addPlannedSessionSheet: some View {
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
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Project")
                        .font(.caption).foregroundColor(.secondary)
                    
                    if isCreatingNewProjectInSheet {
                        VStack(spacing: 12) {
                            TextField("New Project Name", text: $newProjectNameInSheet)
                                .textFieldStyle(.plain)
                                .padding(8)
                                .background(Color(NSColor.controlBackgroundColor))
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
                                                .stroke(Color.primary, lineWidth: newProjectColorInSheet == hex ? 1.5 : 0)
                                        )
                                        .onTapGesture { newProjectColorInSheet = hex }
                                }
                            }
                            
                            HStack {
                                Button("Cancel Project") {
                                    isCreatingNewProjectInSheet = false
                                    newProjectNameInSheet = ""
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(.secondary)
                                .font(.footnote)
                                
                                Spacer()
                                
                                Button("Create & Select") {
                                    if !newProjectNameInSheet.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        let newProj = manager.createProject(name: newProjectNameInSheet, colorHex: newProjectColorInSheet)
                                        plannedSessionProjectId = newProj.id
                                        newProjectNameInSheet = ""
                                        isCreatingNewProjectInSheet = false
                                        plannedSessionTaskGroupId = nil
                                        isCreatingNewGroup = false
                                        plannedSessionGroupTagIds = []
                                        showNewGroupTagInSheet = false
                                        newGroupTagNameInSheet = ""
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
                        HStack {
                            Picker("", selection: $plannedSessionProjectId) {
                                Text("Standalone Session").tag(nil as UUID?)
                                ForEach(manager.projects) { proj in
                                    Text(proj.name).tag(proj.id as UUID?)
                                }
                            }
                            .labelsHidden()
                            .onChange(of: plannedSessionProjectId) { _, _ in
                                plannedSessionTaskGroupId = nil
                                isCreatingNewGroup = false
                                plannedSessionGroupTagIds = []
                                showNewGroupTagInSheet = false
                                newGroupTagNameInSheet = ""
                            }
                            
                            Button(action: {
                                withAnimation { isCreatingNewProjectInSheet = true }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle")
                                    Text("New Project")
                                }
                                .font(.footnote)
                                .foregroundColor(.accentColor)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // Task Group Picker (if project selected)
                if let projId = plannedSessionProjectId {
                    let groups = manager.taskGroups.filter { $0.projectRef == projId }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Task Group")
                            .font(.caption).foregroundColor(.secondary)
                        
                        if isCreatingNewGroup {
                            VStack(spacing: 12) {
                                TextField(isEditingExistingGroupInSheet ? "Edit Group Name" : "New Group Name", text: $newGroupNameInSheet)
                                    .textFieldStyle(.plain)
                                    .padding(8)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(6)
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(NSColor.separatorColor), lineWidth: 1))
                                
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
                                                    isSelected: plannedSessionGroupTagIds.contains(tag.id),
                                                    isCheckable: true
                                                ) {
                                                    if plannedSessionGroupTagIds.contains(tag.id) {
                                                        plannedSessionGroupTagIds.remove(tag.id)
                                                    } else {
                                                        plannedSessionGroupTagIds.insert(tag.id)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    
                                    if showNewGroupTagInSheet {
                                        VStack(spacing: 8) {
                                            TextField("Tag name (e.g. core, experimental)", text: $newGroupTagNameInSheet)
                                                .textFieldStyle(.plain)
                                                .padding(6)
                                                .background(Color(NSColor.controlBackgroundColor))
                                                .cornerRadius(4)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                                                )
                                            
                                            HStack(spacing: 4) {
                                                ForEach(Tag.defaultColors.prefix(5), id: \.self) { hex in
                                                    Circle().fill(Color(hex: hex)).frame(width: 14, height: 14)
                                                        .overlay(
                                                            Circle().stroke(Color.primary, lineWidth: newGroupTagColorInSheet == hex ? 1.5 : 0)
                                                        )
                                                        .onTapGesture { newGroupTagColorInSheet = hex }
                                                }
                                                Spacer()
                                            }
                                            
                                            HStack {
                                                Button("Cancel") {
                                                    showNewGroupTagInSheet = false
                                                    newGroupTagNameInSheet = ""
                                                }
                                                .buttonStyle(.plain)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                
                                                Spacer()
                                                
                                                Button("Create & Add") {
                                                    let t = newGroupTagNameInSheet.trimmingCharacters(in: .whitespacesAndNewlines)
                                                    if !t.isEmpty {
                                                        let tag = manager.createGroupTag(name: t, colorHex: newGroupTagColorInSheet)
                                                        plannedSessionGroupTagIds.insert(tag.id)
                                                        newGroupTagNameInSheet = ""
                                                        showNewGroupTagInSheet = false
                                                    }
                                                }
                                                .buttonStyle(.borderedProminent)
                                                .controlSize(.small)
                                                .disabled(newGroupTagNameInSheet.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                            }
                                        }
                                    } else {
                                        Button(action: { showNewGroupTagInSheet = true }) {
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
                                        isCreatingNewGroup = false
                                        newGroupNameInSheet = ""
                                        plannedSessionGroupTagIds = []
                                        showNewGroupTagInSheet = false
                                        newGroupTagNameInSheet = ""
                                        isEditingExistingGroupInSheet = false
                                        editingGroupIdInSheet = nil
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundColor(.secondary)
                                    .font(.footnote)
                                    
                                    Spacer()
                                    
                                    Button(isEditingExistingGroupInSheet ? "Save Changes" : "Create & Select") {
                                        let t = newGroupNameInSheet.trimmingCharacters(in: .whitespacesAndNewlines)
                                        if !t.isEmpty, let projId = plannedSessionProjectId {
                                            if isEditingExistingGroupInSheet, let editingId = editingGroupIdInSheet {
                                                manager.updateTaskGroup(
                                                    id: editingId,
                                                    name: t,
                                                    tagRefs: Array(plannedSessionGroupTagIds)
                                                )
                                                plannedSessionTaskGroupId = editingId
                                            } else {
                                                let newGroup = manager.createTaskGroup(
                                                    name: t,
                                                    projectRef: projId,
                                                    tagRefs: Array(plannedSessionGroupTagIds)
                                                )
                                                plannedSessionTaskGroupId = newGroup.id
                                            }
                                            newGroupNameInSheet = ""
                                            plannedSessionGroupTagIds = []
                                            isCreatingNewGroup = false
                                            showNewGroupTagInSheet = false
                                            newGroupTagNameInSheet = ""
                                            isEditingExistingGroupInSheet = false
                                            editingGroupIdInSheet = nil
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                    .disabled(newGroupNameInSheet.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                }
                            }
                            .padding(10)
                            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
                            .cornerRadius(8)
                            .transition(.slide.combined(with: .opacity))
                        } else {
                            HStack {
                                Picker("", selection: $plannedSessionTaskGroupId) {
                                    Text("No Group").tag(nil as UUID?)
                                    ForEach(groups) { group in
                                        Text(group.name).tag(group.id as UUID?)
                                    }
                                }
                                .labelsHidden()
                                
                                if plannedSessionTaskGroupId != nil {
                                    Button(action: {
                                        if let groupId = plannedSessionTaskGroupId, let group = groups.first(where: { $0.id == groupId }) {
                                            newGroupNameInSheet = group.name
                                            plannedSessionGroupTagIds = Set(group.tagRefs ?? [])
                                            editingGroupIdInSheet = group.id
                                            isEditingExistingGroupInSheet = true
                                            withAnimation { isCreatingNewGroup = true }
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
                                    isEditingExistingGroupInSheet = false
                                    editingGroupIdInSheet = nil
                                    newGroupNameInSheet = ""
                                    plannedSessionGroupTagIds = []
                                    withAnimation { isCreatingNewGroup = true }
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
                VStack(alignment: .leading, spacing: 6) {
                    Text("Session Tags")
                        .font(.caption).foregroundColor(.secondary)
                    
                    if !manager.tags.isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(manager.tags) { tag in
                                TagChip(
                                    tag: tag,
                                    isSelected: plannedSessionTagIds.contains(tag.id),
                                    isCheckable: true
                                ) {
                                    if plannedSessionTagIds.contains(tag.id) {
                                        plannedSessionTagIds.remove(tag.id)
                                    } else {
                                        plannedSessionTagIds.insert(tag.id)
                                    }
                                }
                            }
                        }
                    }
                    
                    if showNewTagInSheet {
                        HStack {
                            TextField("Tag name", text: $newTagNameInSheet)
                                .textFieldStyle(.plain)
                                .padding(6)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(4)
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(NSColor.separatorColor), lineWidth: 1))
                            
                            HStack(spacing: 4) {
                                ForEach(Tag.defaultColors.prefix(5), id: \.self) { hex in
                                    Circle().fill(Color(hex: hex)).frame(width: 14, height: 14)
                                        .overlay(Circle().stroke(Color.primary, lineWidth: newTagColorInSheet == hex ? 1.5 : 0))
                                        .onTapGesture { newTagColorInSheet = hex }
                                }
                            }
                            
                            Button("Add") {
                                let t = newTagNameInSheet.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !t.isEmpty {
                                    let tag = manager.createTag(name: t, colorHex: newTagColorInSheet)
                                    plannedSessionTagIds.insert(tag.id)
                                    newTagNameInSheet = ""
                                    showNewTagInSheet = false
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .disabled(newTagNameInSheet.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            
                            Button("Cancel") { showNewTagInSheet = false; newTagNameInSheet = "" }
                                .buttonStyle(.plain).font(.caption).foregroundColor(.secondary)
                        }
                    } else {
                        Button(action: { showNewTagInSheet = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle")
                                Text("New Session Tag")
                            }
                            .font(.footnote)
                            .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            HStack {
                Button("Cancel") {
                    showAddPlannedSessionSheet = false
                    plannedSessionTitle = ""
                    plannedSessionTaskGroupId = nil
                    isCreatingNewGroup = false
                    newGroupNameInSheet = ""
                    plannedSessionGroupTagIds = []
                    showNewGroupTagInSheet = false
                    newGroupTagNameInSheet = ""
                    isCreatingNewProjectInSheet = false
                    newProjectNameInSheet = ""
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Save Plan") {
                    let parsed = manager.parseDuration(plannedSessionDurationText)
                    let duration = parsed?.duration ?? 1800 // 30m default
                    
                    var finalGroupId = plannedSessionTaskGroupId
                    if let projId = plannedSessionProjectId, isCreatingNewGroup, !newGroupNameInSheet.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        let group = manager.createTaskGroup(name: newGroupNameInSheet.trimmingCharacters(in: .whitespacesAndNewlines), projectRef: projId, tagRefs: Array(plannedSessionGroupTagIds))
                        finalGroupId = group.id
                    }
                    
                    manager.planSession(
                        title: plannedSessionTitle.isEmpty ? "Planned Work Block" : plannedSessionTitle,
                        duration: duration,
                        projectId: plannedSessionProjectId,
                        taskGroupId: finalGroupId,
                        tagIds: Array(plannedSessionTagIds)
                    )
                    showAddPlannedSessionSheet = false
                    plannedSessionTitle = ""
                    plannedSessionTaskGroupId = nil
                    isCreatingNewGroup = false
                    newGroupNameInSheet = ""
                    plannedSessionGroupTagIds = []
                    showNewGroupTagInSheet = false
                    newGroupTagNameInSheet = ""
                    plannedSessionTagIds = []
                    showNewTagInSheet = false
                    isCreatingNewProjectInSheet = false
                    newProjectNameInSheet = ""
                }
                .buttonStyle(.borderedProminent)
                .disabled(plannedSessionTitle.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 550)
    }
    
    // MARK: - Add Project Sheet
    private var addProjectSheet: some View {
        VStack(spacing: 20) {
            Text("Create New Project")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Project Name")
                        .font(.caption).foregroundColor(.secondary)
                    TextField("e.g. Mobile App, Website redesign", text: $newProjectName)
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(NSColor.separatorColor), lineWidth: 1))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Theme Color")
                        .font(.caption).foregroundColor(.secondary)
                    HStack(spacing: 8) {
                        ForEach(Project.defaultColors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 18, height: 18)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: newProjectColorHex == hex ? 1.5 : 0)
                                )
                                .onTapGesture {
                                    newProjectColorHex = hex
                                }
                        }
                    }
                }
            }
            
            HStack {
                Button("Cancel") {
                    showAddProjectSheet = false
                    newProjectName = ""
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Create Project") {
                    if !newProjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        _ = manager.createProject(name: newProjectName, colorHex: newProjectColorHex)
                        newProjectName = ""
                        showAddProjectSheet = false
                    }
                }
                .buttonStyle(.bordered)
                .disabled(newProjectName.isEmpty)
                
                Button("Create & Plan Session") {
                    if !newProjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        let newProj = manager.createProject(name: newProjectName, colorHex: newProjectColorHex)
                        newProjectName = ""
                        showAddProjectSheet = false
                        
                        // Prefill planning sheet and show it
                        plannedSessionProjectId = newProj.id
                        plannedSessionTitle = ""
                        plannedSessionDurationText = "20 min"
                        
                        // Present the planning sheet after dismissing the current sheet
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showAddPlannedSessionSheet = true
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(newProjectName.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 380)
    }
}

//
//  WorkspaceView.swift
//  TrackIt
//
//  Created by Antigravity on 6/3/26.
//

import SwiftUI

struct WorkspaceView: View {
    @Bindable var manager: SessionFlowManager
    
    @State private var workspaceTab: WorkspaceTab = .dashboard
    @State private var searchText: String = ""
    @State private var selectedProject: Project? = nil
    
    // Inline creation for planned session
    @State private var showAddPlannedSessionSheet: Bool = false
    @State private var plannedSessionTitle: String = ""
    @State private var plannedSessionDurationText: String = "20 min"
    @State private var plannedSessionProjectId: UUID? = nil
    
    enum WorkspaceTab {
        case dashboard
        case search
        case projects
        case reports
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
                SidebarButton(title: "Dashboard", icon: "window.shade.closed.to.open.aspectratio.left", isSelected: workspaceTab == .dashboard) {
                    selectedProject = nil
                    workspaceTab = .dashboard
                }
                
                SidebarButton(title: "Search & Insights", icon: "magnifyingglass", isSelected: workspaceTab == .search) {
                    selectedProject = nil
                    workspaceTab = .search
                }
                
                SidebarButton(title: "Projects", icon: "folder", isSelected: workspaceTab == .projects) {
                    selectedProject = nil
                    workspaceTab = .projects
                }
                
                SidebarButton(title: "Reports", icon: "chart.bar", isSelected: workspaceTab == .reports) {
                    selectedProject = nil
                    workspaceTab = .reports
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
                        ProjectDetailView(project: project) {
                            selectedProject = nil
                        }
                    } else {
                        projectsTab
                    }
                case .reports:
                    reportsTab
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.windowBackgroundColor).allowsHitTesting(false))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showAddPlannedSessionSheet) {
            addPlannedSessionSheet
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
            // Search Input Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search sessions, notes, projects, tags (e.g., 'database')", text: $searchText)
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
            .padding(24)
            
            Divider()
            
            // Search Results & Historical Insights
            let results = searchSessions()
            
            if searchText.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 32))
                        .foregroundColor(.accentColor.opacity(0.7))
                    Text("Search & Insights")
                        .font(.headline)
                    Text("Type a keyword like 'database' or 'auth' to view aggregated analytics and matching sessions.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 320)
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Historical Insights Panel (if results found)
                        if !results.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Historical Insights")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                let totalSecs = results.reduce(0.0) { $0 + $1.duration }
                                let avgSecs = totalSecs / Double(results.count)
                                let uniqueProjCount = Set(results.compactMap { $0.projectRef }).count
                                
                                HStack(spacing: 16) {
                                    InsightCard(title: "Sessions Found", value: "\(results.count)", icon: "doc.text")
                                    InsightCard(title: "Total Time Spent", value: formatHoursMins(totalSecs), icon: "clock")
                                    InsightCard(title: "Avg. Session Duration", value: formatHoursMins(avgSecs), icon: "hourglass")
                                    InsightCard(title: "Impacted Projects", value: "\(uniqueProjCount)", icon: "folder")
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
                        
                        // Result Sessions List
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Matching Sessions (\(results.count))")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            if results.isEmpty {
                                Text("No matching sessions found.")
                                    .foregroundColor(.secondary)
                                    .italic()
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
                }
                
                // Project Cards Grid
                if manager.projects.isEmpty {
                    Text("No projects configured.")
                        .foregroundColor(.secondary)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 280))], spacing: 16) {
                        ForEach(manager.projects) { project in
                            ProjectCard(project: project, manager: manager) {
                                selectedProject = project
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
    }
    
    // MARK: - Reports Tab
    private var reportsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Time Reports")
                        .font(.title2)
                        .bold()
                    Text("Aggregated summaries of work time.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                let completed = manager.sessions.filter { $0.status == .completed }
                let todaySessions = completed.filter { Calendar.current.isDateInToday($0.date) }
                let weekSessions = completed.filter { $0.date.timeIntervalSinceNow > -7 * 24 * 3600 }
                let monthSessions = completed.filter { $0.date.timeIntervalSinceNow > -30 * 24 * 3600 }
                
                let todayTotal = todaySessions.reduce(0.0) { $0 + $1.duration }
                let weekTotal = weekSessions.reduce(0.0) { $0 + $1.duration }
                let monthTotal = monthSessions.reduce(0.0) { $0 + $1.duration }
                
                HStack(spacing: 20) {
                    ReportCard(period: "Today", duration: todayTotal, sessionCount: todaySessions.count)
                    ReportCard(period: "This Week", duration: weekTotal, sessionCount: weekSessions.count)
                    ReportCard(period: "This Month", duration: monthTotal, sessionCount: monthSessions.count)
                }
                
                // Breakdown by Project
                VStack(alignment: .leading, spacing: 12) {
                    Text("Time Breakdown by Project")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    let projectsWithDurations = getProjectTimeBreakdown()
                    
                    if projectsWithDurations.isEmpty {
                        Text("No recorded data to display in breakdown.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 10)
                    } else {
                        VStack(spacing: 14) {
                            let maxDuration = projectsWithDurations.map { $0.duration }.max() ?? 1.0
                            
                            ForEach(projectsWithDurations, id: \.name) { item in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        HStack(spacing: 6) {
                                            Circle()
                                                .fill(Color(hex: item.colorHex))
                                                .frame(width: 8, height: 8)
                                            Text(item.name)
                                                .fontWeight(.medium)
                                        }
                                        Spacer()
                                        Text(formatHoursMins(item.duration))
                                            .foregroundColor(.secondary)
                                            .font(.system(.body, design: .monospaced))
                                    }
                                    
                                    // Progress Bar
                                    GeometryReader { geo in
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.secondary.opacity(0.1))
                                            .frame(height: 8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color(hex: item.colorHex))
                                                    .frame(width: geo.size.width * CGFloat(item.duration / maxDuration), height: 8),
                                                alignment: .leading
                                            )
                                    }
                                    .frame(height: 8)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.secondary.opacity(0.04))
                        .cornerRadius(10)
                    }
                }
            }
            .padding(24)
        }
    }
    
    // MARK: - Helpers & Data Computations
    
    private func searchSessions() -> [Session] {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if keyword.isEmpty { return [] }
        
        return manager.sessions.filter { session in
            let titleMatch = session.title.lowercased().contains(keyword)
            let notesMatch = session.notes.lowercased().contains(keyword)
            
            var projectMatch = false
            if let projId = session.projectRef,
               let proj = manager.projects.first(where: { $0.id == projId }) {
                projectMatch = proj.name.lowercased().contains(keyword)
            }
            
            return titleMatch || notesMatch || projectMatch
        }
    }
    
    private func getProjectTimeBreakdown() -> [(name: String, colorHex: String, duration: TimeInterval)] {
        var breakdown: [UUID?: TimeInterval] = [:]
        
        let completed = manager.sessions.filter { $0.status == .completed }
        for session in completed {
            breakdown[session.projectRef, default: 0.0] += session.duration
        }
        
        var resultList: [(name: String, colorHex: String, duration: TimeInterval)] = []
        for (ref, dur) in breakdown {
            if let ref = ref, let proj = manager.projects.first(where: { $0.id == ref }) {
                resultList.append((proj.name, proj.colorHex, dur))
            } else if ref == nil {
                resultList.append(("Standalone Sessions", "#8E8E93", dur))
            }
        }
        
        return resultList.sorted(by: { $0.duration > $1.duration })
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
                    Picker("", selection: $plannedSessionProjectId) {
                        Text("Standalone Session").tag(nil as UUID?)
                        ForEach(manager.projects) { proj in
                            Text(proj.name).tag(proj.id as UUID?)
                        }
                    }
                    .labelsHidden()
                }
            }
            
            HStack {
                Button("Cancel") {
                    showAddPlannedSessionSheet = false
                    plannedSessionTitle = ""
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Save Plan") {
                    let parsed = manager.parseDuration(plannedSessionDurationText)
                    let duration = parsed?.duration ?? 1800 // 30m default
                    
                    let plannedSession = Session(
                        title: plannedSessionTitle.isEmpty ? "Planned Work Block" : plannedSessionTitle,
                        duration: duration,
                        date: Date(),
                        notes: "",
                        projectRef: plannedSessionProjectId,
                        status: .planned
                    )
                    manager.sessions.insert(plannedSession, at: 0)
                    showAddPlannedSessionSheet = false
                    plannedSessionTitle = ""
                }
                .buttonStyle(.borderedProminent)
                .disabled(plannedSessionTitle.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 350)
    }
}

// MARK: - Subviews

struct SidebarButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 16)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                Text(title)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : (isHovered ? Color.secondary.opacity(0.08) : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .foregroundColor(isSelected ? .accentColor : .primary)
        .padding(.horizontal, 8)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.1), value: isSelected)
        .animation(.easeInOut(duration: 0.1), value: isHovered)
    }
}

struct PlannedSessionRow: View {
    let session: Session
    let manager: SessionFlowManager
    
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
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.1), lineWidth: 1))
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let mins = Int(duration) / 60
        return "\(mins) min"
    }
}

struct CompletedSessionRow: View {
    let session: Session
    let manager: SessionFlowManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(session.title)
                    .fontWeight(.semibold)
                Spacer()
                Text(formatDuration(session.duration))
                    .font(.system(.body, design: .monospaced))
                    .bold()
                
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
            
            if !session.notes.isEmpty {
                Text(session.notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.04))
                    .cornerRadius(4)
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.08), lineWidth: 1))
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hrs = Int(duration) / 3600
        let mins = (Int(duration) % 3600) / 60
        let secs = Int(duration) % 60
        return String(format: "%02d:%02d:%02d", hrs, mins, secs)
    }
}

struct ProjectCard: View {
    let project: Project
    let manager: SessionFlowManager
    let onSelect: () -> Void
    
    var body: some View {
        let relatedSessions = manager.sessions.filter { $0.projectRef == project.id && $0.status == .completed }
        let totalDuration = relatedSessions.reduce(0.0) { $0 + $1.duration }
        
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Circle().fill(Color(hex: project.colorHex)).frame(width: 10, height: 10)
                    Text(project.name)
                        .font(.headline)
                        .fontWeight(.bold)
                }
                Spacer()
                
                Button(action: {
                    withAnimation {
                        manager.deleteProject(id: project.id)
                    }
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatDuration(totalDuration))
                        .font(.system(.title3, design: .monospaced))
                        .bold()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sessions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(relatedSessions.count)")
                        .font(.title3)
                        .bold()
                }
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: project.colorHex).opacity(0.2), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hrs = Int(duration) / 3600
        let mins = (Int(duration) % 3600) / 60
        return "\(hrs)h \(mins)m"
    }
}

struct InsightCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Spacer()
            }
            Text(value)
                .font(.title2)
                .bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.1), lineWidth: 1))
    }
}

struct ReportCard: View {
    let period: String
    let duration: TimeInterval
    let sessionCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(period)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            Text(formatDuration(duration))
                .font(.system(.title, design: .monospaced))
                .bold()
            
            Text("\(sessionCount) Sessions")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.1), lineWidth: 1))
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hrs = Int(duration) / 3600
        let mins = (Int(duration) % 3600) / 60
        let secs = Int(duration) % 60
        return String(format: "%02d:%02d:%02d", hrs, mins, secs)
    }
}

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
        VStack(spacing: 20) {
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
            .padding(.bottom, 5)
            
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
                            .background(Color(NSColor.controlBackgroundColor))
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
                            
                            // Existing groups picker (for established projects)
                            if !groups.isEmpty {
                                Picker("", selection: $selectedTaskGroupId) {
                                    Text("Ungrouped").tag(nil as UUID?)
                                    ForEach(groups) { group in
                                        Text(group.name).tag(group.id as UUID?)
                                    }
                                }
                                .labelsHidden()
                            }
                            
                            // Inline New Group Creator (when a new project was just created)
                            if justCreatedNewProject {
                                if showNewGroupField {
                                    VStack(spacing: 12) {
                                        TextField("New Group Name (e.g. Frontend, Backend)", text: $newGroupName)
                                            .textFieldStyle(.plain)
                                            .padding(8)
                                            .background(Color(NSColor.controlBackgroundColor))
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
                                            Button("Cancel Group") {
                                                showNewGroupField = false
                                                newGroupName = ""
                                                selectedGroupTagIds = []
                                                showNewGroupTagField = false
                                                newGroupTagName = ""
                                            }
                                            .buttonStyle(.plain)
                                            .foregroundColor(.secondary)
                                            .font(.footnote)
                                            
                                            Spacer()
                                            
                                            Button("Create & Select") {
                                                let t = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
                                                if !t.isEmpty, let projId = selectedProjectId {
                                                    let newGroup = manager.createTaskGroup(
                                                        name: t,
                                                        projectRef: projId,
                                                        tagRefs: Array(selectedGroupTagIds)
                                                    )
                                                    selectedTaskGroupId = newGroup.id
                                                    newGroupName = ""
                                                    selectedGroupTagIds = []
                                                    showNewGroupField = false
                                                    showNewGroupTagField = false
                                                    newGroupTagName = ""
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
                                    if groups.isEmpty {
                                        HStack(spacing: 6) {
                                            Image(systemName: "tray")
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                            Text("Session will be ungrouped")
                                                .font(.footnote)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Button(action: {
                                        withAnimation {
                                            showNewGroupField = true
                                        }
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "plus.circle")
                                            Text("New Group")
                                        }
                                        .font(.footnote)
                                        .foregroundColor(.accentColor)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.top, 2)
                                }
                            } else if groups.isEmpty {
                                Text("No task groups in this project.")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Tags Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
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
                            Text("No tags created yet.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        
                        if showNewTagField {
                            VStack(spacing: 10) {
                                TextField("Tag name (e.g. database, UI, bug fix)", text: $newTagName)
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
                                    Text("New Tag")
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
                            .background(Color(NSColor.controlBackgroundColor))
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
                    dismiss()
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
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.return, modifiers: [])
            }
        }
        .padding(24)
        .frame(width: 440)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
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

// MARK: - FlowLayout helper for Wrapping Project Badges
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let width = proposal.width ?? 400
        
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for size in sizes {
            if currentX + size.width > width {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
        }
        height = currentY + rowHeight
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let width = bounds.width
        
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        
        for index in subviews.indices {
            let size = sizes[index]
            if currentX + size.width > bounds.minX + width {
                currentX = bounds.minX
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            subviews[index].place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(size))
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
        }
    }
}

// MARK: - Project Badge View
struct ProjectBadge: View {
    let name: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? Color.accentColor : (isHovered ? Color.secondary.opacity(0.15) : Color.secondary.opacity(0.08)))
        )
        .onTapGesture(perform: action)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}

// MARK: - Tag Chip View
struct TagChip: View {
    let tag: Tag
    var isSelected: Bool = false
    var isCheckable: Bool = false
    var action: (() -> Void)? = nil
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        HStack(spacing: 4) {
            if isCheckable {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 9))
                    .foregroundColor(isSelected ? .white : Color(hex: tag.colorHex))
            } else {
                Circle()
                    .fill(Color(hex: tag.colorHex))
                    .frame(width: 6, height: 6)
            }
            
            Text(tag.name)
                .font(.system(size: 11))
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color(hex: tag.colorHex) : (isHovered ? Color(hex: tag.colorHex).opacity(0.15) : Color(hex: tag.colorHex).opacity(0.08)))
        )
        .onTapGesture { action?() }
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}

// MARK: - Color Hex Ext
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Visual Effect View for macOS
class DraggableVisualEffectNSView: NSVisualEffectView {
    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            return
        }
        self.window?.performDrag(with: event)
    }
}

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = DraggableVisualEffectNSView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

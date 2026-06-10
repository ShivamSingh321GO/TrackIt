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
    
    // For creating a new project inline
    @State private var showNewProjectField: Bool = false
    @State private var newProjectName: String = ""
    @State private var selectedColorHex: String = Project.defaultColors.first ?? "#4A90E2"
    
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
                                }
                                
                                // Project Badges
                                ForEach(manager.projects) { proj in
                                    ProjectBadge(
                                        name: proj.name,
                                        color: Color(hex: proj.colorHex),
                                        isSelected: selectedProjectId == proj.id
                                    ) {
                                        selectedProjectId = proj.id
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
                        duration: duration
                    )
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
                notes = activeSession.notes
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

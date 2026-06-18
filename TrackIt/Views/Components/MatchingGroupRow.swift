import SwiftUI

struct MatchingGroupRow: View {
    let group: TaskGroup
    let manager: SessionFlowManager
    let onSelect: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    var isDark: Bool {
        if manager.appTheme == "Dark" { return true }
        if manager.appTheme == "Light" { return false }
        return colorScheme == .dark
    }
    
    @State private var isHovered = false
    
    var body: some View {
        let sessionsInGroup = manager.sessions.filter { $0.taskGroupRef == group.id }
        let completed = sessionsInGroup.filter { $0.status == .completed }
        let totalDuration = completed.reduce(0.0) { $0 + $1.duration }
        let project = manager.projects.first { $0.id == group.projectRef }
        
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "folder.fill")
                        .foregroundColor(.accentColor)
                    Text(group.name)
                        .fontWeight(.semibold)
                    
                    if let proj = project {
                        Text("•")
                            .foregroundColor(.secondary)
                        Circle()
                            .fill(Color(hex: proj.colorHex))
                            .frame(width: 6, height: 6)
                        Text(proj.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 12) {
                    Text("\(completed.count)/\(sessionsInGroup.count) Sessions Done")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    
                    Text("Total Time: \(formatDuration(totalDuration))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Group Tags
                let tags = (group.tagRefs ?? []).compactMap { tagId in
                    manager.groupTags.first { $0.id == tagId }
                }
                if !tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(tags) { tag in
                            TagChip(tag: tag)
                        }
                    }
                }
            }
            
            Spacer()
            
            Button(action: onSelect) {
                HStack(spacing: 4) {
                    Text("View Project")
                    Image(systemName: "arrow.right")
                }
                .font(.footnote)
                .bold()
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.accentColor.opacity(0.12))
                .foregroundColor(.accentColor)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background((isDark ? Color(red: 0.10, green: 0.10, blue: 0.12) : Color(red: 0.97, green: 0.97, blue: 0.98)).opacity(0.6))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.08), lineWidth: 1)
        )
        .onHover { hovering in
            isHovered = hovering
            if hovering {
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

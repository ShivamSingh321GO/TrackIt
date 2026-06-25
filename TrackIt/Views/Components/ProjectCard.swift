import SwiftUI

struct ProjectCard: View {
    let project: Project
    let manager: SessionFlowManager
    let onSelect: () -> Void
    let onPlanSession: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    var isDark: Bool {
        if manager.appTheme == "Dark" { return true }
        if manager.appTheme == "Light" { return false }
        return colorScheme == .dark
    }
    
    @State private var isPlanHovered = false
    
    var body: some View {
        let allSessions = manager.sessions.filter { $0.projectRef == project.id }
        let completedSessions = allSessions.filter { $0.status == .completed }
        let totalDuration = completedSessions.reduce(0.0) { $0 + $1.duration }
        
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Circle().fill(Color(hex: project.colorHex)).frame(width: 10, height: 10)
                    Text(project.name)
                        .font(.headline)
                        .fontWeight(.bold)
                }
                Spacer()
                
                Button(action: onPlanSession) {
                    Image(systemName: "calendar.badge.plus")
                        .foregroundColor(isPlanHovered ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .onHover { isPlanHovered = $0 }
                .padding(.trailing, 8)
                
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
            
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatDuration(totalDuration))
                        .font(.system(.title3, design: .monospaced))
                        .bold()
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Sessions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(allSessions.count)")
                        .font(.title3)
                        .bold()
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Completed Sessions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(completedSessions.count)")
                        .font(.title3)
                        .bold()
                }
            }
            
            HStack {
                Spacer()
                Text("Created: \(formatDate(project.createdAt))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(manager.appTheme == "Glass" ? Color.white.opacity(isDark ? 0.05 : 0.4) : (isDark ? Color(red: 0.10, green: 0.10, blue: 0.12) : Color(red: 0.97, green: 0.97, blue: 0.98)))
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "d MMMM, yyyy 'at' h:mm a"
        return formatter.string(from: date).lowercased()
    }
}

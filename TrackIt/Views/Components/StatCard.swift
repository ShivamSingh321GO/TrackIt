import SwiftUI

struct InsightCard: View {
    let title: String
    let value: String
    let icon: String
    
    @Environment(\.colorScheme) var colorScheme
    var isDark: Bool { return colorScheme == .dark }
    
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
        .background(isDark ? Color(red: 0.10, green: 0.10, blue: 0.12) : Color(red: 0.97, green: 0.97, blue: 0.98))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.1), lineWidth: 1))
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = .accentColor
    
    @Environment(\.colorScheme) var colorScheme
    var isDark: Bool { return colorScheme == .dark }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
            }
            Text(value)
                .font(.system(.title2, design: .monospaced))
                .bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(isDark ? Color(red: 0.10, green: 0.10, blue: 0.12) : Color(red: 0.97, green: 0.97, blue: 0.98))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

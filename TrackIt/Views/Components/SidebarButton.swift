import SwiftUI

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

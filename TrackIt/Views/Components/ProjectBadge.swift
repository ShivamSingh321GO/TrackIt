import SwiftUI

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

import SwiftUI

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

import SwiftUI

// MARK: - FlowLayout helper for Wrapping Views
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

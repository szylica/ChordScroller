import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat
    var lineSpacing: CGFloat
    
    init(spacing: CGFloat = 0, lineSpacing: CGFloat = 8) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.totalSize
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        
        for (index, pos) in result.positions.enumerated() where index < subviews.count {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + pos.x, y: bounds.minY + pos.y),
                proposal: .unspecified
            )
        }
    }
    
    private struct LayoutResult {
        let totalSize: CGSize
        let positions: [CGPoint]
    }
    
    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> LayoutResult {
        // Użyj proponowanej szerokości, fallback na dużą wartość
        let maxWidth = proposal.width ?? 10000
        
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0
        
        for subview in subviews {
            // Mierz idealny rozmiar (bez ograniczeń)
            let size = subview.sizeThatFits(.unspecified)
            
            // Sprawdź czy mieści się w obecnej linii
            if x > 0 && x + size.width > maxWidth {
                // Nowa linia
                x = 0
                y += rowHeight + lineSpacing
                rowHeight = 0
            }
            
            positions.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            maxX = max(maxX, x)
            rowHeight = max(rowHeight, size.height)
        }
        
        let totalHeight = y + rowHeight
        return LayoutResult(
            totalSize: CGSize(width: maxWidth, height: totalHeight),
            positions: positions
        )
    }
}

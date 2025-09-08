import SwiftUI

struct DotOverlay: ViewModifier {
    let offsetPercentage: CGFloat = 0.33
    let size: CGSize
    let visible: Bool
    let color: Color
    let offset: CGPoint

    init(size: CGSize = .init(width: 8, height: 8), visible: Bool = true, color: Color = .themeRed) {
        self.size = size
        self.visible = visible
        self.color = color
        offset = .init(x: (size.width * offsetPercentage).rounded(), y: (size.height * offsetPercentage).rounded())
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if visible {
                        Circle()
                            .fill(color)
                            .frame(width: size.width, height: size.height)
                            .offset(x: offset.x, y: -offset.y)
                    }
                },
                alignment: .topTrailing
            )
    }
}

extension View {
    func dotOverlay(size: CGSize = .init(width: 8, height: 8), visible: Bool = true, color: Color = .themeRed) -> some View {
        modifier(DotOverlay(size: size, visible: visible, color: color))
    }
}

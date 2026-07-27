import SwiftUI

public struct HorizontalDivider: View {
    private let color: Color
    private let height: CGFloat

    public init(color: Color = .themeBlade, height: CGFloat = .heightOnePixel) {
        self.color = color
        self.height = height
    }

    public var body: some View {
        color.frame(height: height)
    }
}

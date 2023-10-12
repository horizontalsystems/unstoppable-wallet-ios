import SwiftUI

struct HorizontalDivider: View {
    private let color: Color
    private let height: CGFloat

    init(color: Color = .themeSteel10, height: CGFloat = .heightOneDp) {
        self.color = color
        self.height = height
    }

    var body: some View {
        color.frame(height: height)
    }
}

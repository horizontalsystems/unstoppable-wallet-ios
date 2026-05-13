import SwiftUI

extension View {
    func frame(size: CGFloat) -> some View {
        frame(width: size, height: size)
    }

    @ViewBuilder func applyFrame(size: CGSize?) -> some View {
        if let size {
            frame(width: size.width, height: size.height)
        } else {
            self
        }
    }
}

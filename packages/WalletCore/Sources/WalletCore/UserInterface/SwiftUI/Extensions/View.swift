import SwiftUI

extension View {
    func frame(size: CGFloat) -> some View {
        frame(width: size, height: size)
    }
}

extension View {
    @ViewBuilder func applyFrame(size: CGSize?) -> some View {
        if let size {
            frame(width: size.width, height: size.height)
        } else {
            self
        }
    }

    @ViewBuilder func tapIntercept(active: Bool, action: @escaping () -> Void) -> some View {
        if active {
            overlay {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture(perform: action)
            }
        } else {
            self
        }
    }
}

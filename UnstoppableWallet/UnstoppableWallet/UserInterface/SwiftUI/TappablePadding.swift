import SwiftUI

struct TappablePadding: ViewModifier {
    let insets: EdgeInsets
    let onTap: () -> Void

    func body(content: Content) -> some View {
        content
            .padding(insets)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
            .padding(insets.inverted)
    }
}

extension View {
    func tappablePadding(_ insets: EdgeInsets, onTap: @escaping () -> Void) -> some View {
        modifier(TappablePadding(insets: insets, onTap: onTap))
    }

    func tappablePadding(_ inset: CGFloat, onTap: @escaping () -> Void) -> some View {
        modifier(TappablePadding(insets: EdgeInsets(top: inset, leading: inset, bottom: inset, trailing: inset), onTap: onTap))
    }
}

extension EdgeInsets {
    var inverted: EdgeInsets {
        .init(top: -top, leading: -leading, bottom: -bottom, trailing: -trailing)
    }
}

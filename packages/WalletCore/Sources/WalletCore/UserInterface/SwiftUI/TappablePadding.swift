import SwiftUI

struct TappablePadding: ViewModifier {
    let insets: EdgeInsets
    let onTap: () -> Void

    func body(content: Content) -> some View {
        content
            .tapAreaPadding(insets)
            .onTapGesture {
                onTap()
            }
    }
}

extension View {
    func tappablePadding(_ insets: EdgeInsets, onTap: @escaping () -> Void) -> some View {
        modifier(TappablePadding(insets: insets, onTap: onTap))
    }

    func tappablePadding(_ inset: CGFloat, onTap: @escaping () -> Void) -> some View {
        modifier(TappablePadding(insets: EdgeInsets(top: inset, leading: inset, bottom: inset, trailing: inset), onTap: onTap))
    }

    func tapAreaPadding(_ insets: EdgeInsets) -> some View {
        padding(insets)
            .contentShape(Rectangle())
            .padding(insets.inverted)
    }

    func tapAreaPadding(_ inset: CGFloat) -> some View {
        tapAreaPadding(EdgeInsets(top: inset, leading: inset, bottom: inset, trailing: inset))
    }
}

extension EdgeInsets {
    static let zero = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    static let padding16 = EdgeInsets(top: 0, leading: .margin16, bottom: 0, trailing: .margin16)

    var inverted: EdgeInsets {
        .init(top: -top, leading: -leading, bottom: -bottom, trailing: -trailing)
    }
}

import SwiftUI

struct Cell<Left: View, Middle: View, Right: View>: View {
    private let style: Style
    private let left: Left
    private let middle: Middle
    private let right: Right
    private let action: (() -> Void)?

    init(
        style: Style = .primary,
        @ViewBuilder left: () -> Left = { EmptyView() },
        @ViewBuilder middle: () -> Middle,
        @ViewBuilder right: () -> Right = { EmptyView() },
        action: (() -> Void)? = nil,
    ) {
        self.style = style
        self.left = left()
        self.middle = middle()
        self.right = right()
        self.action = action
    }

    var body: some View {
        if let action {
            Button(action: action) {
                content()
            }
            .buttonStyle(CellButtonStyle())
        } else {
            content()
        }
    }

    @ViewBuilder func content() -> some View {
        HStack(spacing: .margin16) {
            left
            middle
            Spacer()
            right
        }
        .padding(style.insets)
    }

    enum Style {
        case primary
        case secondary

        var insets: EdgeInsets {
            switch self {
            case .primary: return EdgeInsets(top: .margin16, leading: .margin16, bottom: .margin16, trailing: .margin16)
            case .secondary: return EdgeInsets(top: .margin8, leading: .margin16, bottom: .margin8, trailing: .margin16)
            }
        }
    }
}

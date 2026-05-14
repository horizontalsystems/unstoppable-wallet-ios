import SwiftUI

struct ThemeSelector: View {
    var style: Style = .circle
    var size: CGFloat = 24
    @Binding var checked: Bool

    var body: some View {
        Button {
            checked.toggle()
        } label: {
            Group {
                if checked {
                    ThemeImage(style.checkedIcon, size: size, color: .themeLimeD)
                } else {
                    switch style {
                    case .circle:
                        Circle()
                            .strokeBorder(Color.themeGray, lineWidth: 1)
                            .frame(size: size)
                    case .check:
                        Color.clear.frame(size: size)
                    case .heart:
                        ThemeImage("heart", size: size, color: .themeGray)
                    }
                }
            }
            .padding(12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(-12)
    }
}

extension ThemeSelector {
    enum Style {
        case circle
        case check
        case heart

        var checkedIcon: String {
            switch self {
            case .circle: "done_e_filled_full"
            case .check: "check"
            case .heart: "heart_filled"
            }
        }
    }
}

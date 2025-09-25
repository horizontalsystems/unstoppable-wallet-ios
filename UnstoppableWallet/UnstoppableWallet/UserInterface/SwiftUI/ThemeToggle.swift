import SwiftUI

struct ThemeToggle: View {
    let isOn: Binding<Bool>
    let style: ThemeToggleStyle

    init(isOn: Binding<Bool>, style: ThemeToggleStyle) {
        self.isOn = isOn
        self.style = style
    }

    var body: some View {
        Toggle(isOn: isOn) {}
            .toggleStyle(style.makeToggleStyle())
            .fixedSize()
    }
}

extension ThemeToggle {
    enum ThemeToggleStyle: Equatable {
        case yellow

        func makeToggleStyle() -> some ToggleStyle {
            switch self {
            case .yellow: SwitchToggleStyle(tint: .themeYellow)
            }
        }
    }
}

import SwiftUI

struct ThemeToggle: View {
    let isOn: Binding<Bool>
    let style: ThemeToggleStyle

    init(isOn: Binding<Bool>, style: ThemeToggleStyle = .brand) {
        self.isOn = isOn
        self.style = style
    }

    init(isOn: Bool, style: ThemeToggleStyle = .brand, onToggle: @escaping (Bool) -> Void) {
        self.isOn = Binding(
            get: { isOn },
            set: { onToggle($0) }
        ).animation()
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
        case brand

        func makeToggleStyle() -> some ToggleStyle {
            switch self {
            case .brand: SwitchToggleStyle(tint: .themeBrand)
            }
        }
    }
}

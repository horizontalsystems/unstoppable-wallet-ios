import Combine
import Foundation

final class ButtonGroupViewModel: ObservableObject {
    @Published private(set) var buttonStates: [String: ButtonState] = [:]

    func append(id: String, isDisabled: Bool = false) {
        buttonStates[id] = ButtonState(isDisabled: isDisabled)
    }

    func isDisabled(_ buttonId: String) -> Bool {
        buttonStates[buttonId]?.isDisabled ?? false
    }

    func setDisabled(_ isDisabled: Bool, for buttonId: String) {
        buttonStates[buttonId]?.isDisabled = isDisabled
    }

    func removeButton(_ id: String) {
        buttonStates.removeValue(forKey: id)
    }
}

extension ButtonGroupViewModel {
    struct ButtonState {
        var isDisabled: Bool
    }

    struct ButtonGroup: Identifiable {
        let id: String
        let buttons: [ButtonItem]
        let alignment: Alignment

        init(
            id: String = UUID().description,
            buttons: [ButtonItem],
            alignment: Alignment = .vertical
        ) {
            self.id = id
            self.buttons = buttons
            self.alignment = alignment
        }

        enum Alignment {
            case horizontal
            case vertical
        }
    }

    struct ButtonItem: Identifiable {
        let id: String
        let style: PrimaryButtonStyle.Style
        let title: String
        let icon: String?
        let action: () -> Void

        init(
            id: String = UUID().description,
            style: PrimaryButtonStyle.Style,
            title: String,
            icon: String? = nil,
            action: @escaping () -> Void
        ) {
            self.id = id
            self.style = style
            self.title = title
            self.icon = icon
            self.action = action
        }
    }
}

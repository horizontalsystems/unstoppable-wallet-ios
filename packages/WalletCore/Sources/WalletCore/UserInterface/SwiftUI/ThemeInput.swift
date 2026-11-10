import SwiftUI

struct ThemeInput<Content: View>: View {
    private let kind: ThemeInputKind
    private let state: ThemeInputState
    private let description: String?
    private let descriptionIdentifier: String?
    private let buttons: [ThemeInputButton]
    private let content: Content

    init(
        kind: ThemeInputKind = .field,
        state: ThemeInputState = .normal,
        description: String? = nil,
        descriptionIdentifier: String? = nil,
        buttons: [ThemeInputButton] = [],
        @ViewBuilder content: () -> Content
    ) {
        self.kind = kind
        self.state = state
        self.description = description
        self.descriptionIdentifier = descriptionIdentifier
        self.buttons = buttons
        self.content = content()
    }

    init(
        kind: ThemeInputKind = .field,
        caution: CautionState,
        description: String? = nil,
        descriptionIdentifier: String? = nil,
        buttons: [ThemeInputButton] = [],
        @ViewBuilder content: () -> Content
    ) {
        let state: ThemeInputState
        let resolvedDescription: String?

        switch caution {
        case .none:
            state = .normal
            resolvedDescription = description
        case let .caution(caution):
            switch caution.type {
            case .error: state = .error
            case .warning: state = .warning
            case .regular: state = .normal
            }
            resolvedDescription = caution.text
        }

        self.init(
            kind: kind,
            state: state,
            description: resolvedDescription,
            descriptionIdentifier: descriptionIdentifier,
            buttons: buttons,
            content: content
        )
    }

    var body: some View {
        VStack(spacing: .margin8) {
            form
                .overlay(
                    RoundedRectangle(cornerRadius: .cornerRadius16, style: .continuous)
                        .stroke(state.borderColor, lineWidth: .heightOneDp)
                )

            if let description, !description.isEmpty {
                descriptionView(text: description)
            }
        }
    }

    @ViewBuilder private var form: some View {
        switch kind {
        case .field:
            // An empty buttons group measures zero width, so PrimarySizedHStack reserves no trailing space
            PrimarySizedHStack(spacing: .margin16) {
                inputContent.frame(minHeight: .buttonSize32)
            } trailing: {
                buttonsGroup
            }
            .padding(.margin16)
        case .area:
            VStack(alignment: .trailing, spacing: .margin16) {
                inputContent.frame(maxWidth: .infinity, alignment: .topLeading)

                if !buttons.isEmpty {
                    buttonsGroup
                }
            }
            .padding(.margin16)
        }
    }

    private var inputContent: some View {
        content.environment(\.isInsideThemeInput, true)
    }

    private var buttonsGroup: some View {
        HStack(spacing: .margin12) {
            ForEach(buttons) { button in
                buttonView(button)
            }
        }
    }

    @ViewBuilder private func buttonView(_ button: ThemeInputButton) -> some View {
        let view = Group {
            switch button.kind {
            case let .icon(name):
                IconButton(icon: name, style: .secondary, size: .small) { button.action() }
            case let .text(text):
                ThemeButton(text: text, style: .secondary, size: .small) { button.action() }
            }
        }

        if let identifier = button.identifier {
            view.accessibilityIdentifier(identifier)
        } else {
            view
        }
    }

    @ViewBuilder private func descriptionView(text: String) -> some View {
        let view = ThemeText(text, style: .caption, colorStyle: state.descriptionColorStyle)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, .margin16)

        if let descriptionIdentifier {
            view.accessibilityIdentifier(descriptionIdentifier)
        } else {
            view
        }
    }
}

enum ThemeInputKind {
    case field
    case area
}

enum ThemeInputState: Equatable {
    case normal
    case error
    case warning

    init(_ fieldCautionState: FieldCautionState) {
        switch fieldCautionState {
        case .none, .caution(.regular): self = .normal
        case .caution(.error): self = .error
        case .caution(.warning): self = .warning
        }
    }

    var borderColor: Color {
        switch self {
        case .normal: return .themeAndy
        case .error: return .themeLucian
        case .warning: return .themeJacob
        }
    }

    var descriptionColorStyle: ColorStyle {
        switch self {
        case .normal: return .secondary
        case .error: return .red
        case .warning: return .warning
        }
    }
}

private struct IsInsideThemeInputKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isInsideThemeInput: Bool {
        get { self[IsInsideThemeInputKey.self] }
        set { self[IsInsideThemeInputKey.self] = newValue }
    }
}

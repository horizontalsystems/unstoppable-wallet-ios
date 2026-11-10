import MarketKit
import SwiftUI

struct AddressViewNew: View {
    private let maxLineLimit = 6
    private let placeholder = "send.address_or_domain_placeholder".localized

    @StateObject var viewModel: AddressViewModelNew

    @Binding var text: String
    @Binding var result: AddressInput.Result
    @Binding var foregroundColor: Color
    private let isInvalid: Bool
    private let identifier: String?
    private let buttonIdentifiers: ButtonIdentifiers?

    @State private var fieldText = ""

    init(initial: AddressInput.Initial, text: Binding<String>, result: Binding<AddressInput.Result>, parserFilter: AddressParserFactory.ParserFilter?, isInvalid: Bool, foregroundColor: Binding<Color> = .constant(.themeLeah), identifier: String? = nil, buttonIdentifiers: ButtonIdentifiers? = nil) {
        _viewModel = StateObject(wrappedValue: AddressViewModelNew(initial: initial, parserFilter: parserFilter))

        _text = text
        _result = result
        _foregroundColor = foregroundColor
        self.isInvalid = isInvalid
        self.identifier = identifier
        self.buttonIdentifiers = buttonIdentifiers
    }

    var body: some View {
        ThemeInput(kind: .field, state: isInvalid ? .error : .normal, buttons: buttons) {
            textField(
                placeholder: placeholder,
                text: $fieldText
            )
            .onAppear {
                viewModel.text = text
                fieldText = text
            }
            .onChange(of: fieldText) { _, fieldText in
                if viewModel.text != fieldText {
                    viewModel.text = fieldText
                }
            }
            .onChange(of: text) { _, newText in
                if newText != viewModel.text {
                    viewModel.text = newText
                }
            }
            .onChange(of: viewModel.text) { _, newText in
                if newText != text {
                    text = newText
                }

                // A vertical TextField keeps a stale height if its text and width change in the same
                // layout pass (iOS 27), so external text is applied after the buttons have been laid out
                DispatchQueue.main.async {
                    if fieldText != viewModel.text {
                        fieldText = viewModel.text
                    }
                }
            }
            .onChange(of: viewModel.result) { _, newResult in
                if newResult != result {
                    result = newResult
                }
            }
            .font(.themeBody)
            .foregroundStyle(foregroundColor)
            .tint(.themeInputFieldTintColor)
            .autocorrectionDisabled()
            .autocapitalization(.none)
        }
    }

    private var buttons: [ThemeInputButton] {
        guard viewModel.text.isEmpty else {
            return [.delete(identifier: buttonIdentifiers?.clear) { viewModel.onTapDelete() }]
        }

        return viewModel.shortcuts.enumerated().map { index, shortcut in
            switch shortcut {
            case let .icon(name):
                return .icon(name, identifier: buttonIdentifiers?.identifier(icon: name)) { viewModel.onTap(index: index) }
            case let .text(title):
                return .text(title, identifier: buttonIdentifiers?.paste) { viewModel.onTap(index: index) }
            }
        }
    }

    @ViewBuilder func textField(placeholder: String, text: Binding<String>) -> some View {
        let field = baseTextField(placeholder: placeholder, text: text)

        if let identifier {
            field.accessibilityIdentifier(identifier)
        } else {
            field
        }
    }

    private func baseTextField(placeholder: String, text: Binding<String>) -> some View {
        TextField(
            placeholder,
            text: text,
            prompt: Text(placeholder).foregroundColor(.themeAndy),
            axis: .vertical
        )
        .lineLimit(1 ... maxLineLimit)
    }
}

extension AddressViewNew {
    struct ButtonIdentifiers {
        let scan: String?
        let paste: String?
        let contacts: String?
        let clear: String?

        /// the icon names come from AddressViewModelNew.shortcuts
        func identifier(icon: String) -> String? {
            switch icon {
            case "scan": return scan
            case "user": return contacts
            default: return nil
            }
        }
    }
}

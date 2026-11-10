import SwiftUI

struct InputTextView: View {
    var placeholder: String = ""
    var multiline: Bool
    var font: Font

    var text: Binding<String>

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isInsideThemeInput) private var isInsideThemeInput
    @Binding var secured: Bool
    var secureToggleEnabled = false
    var secureIdentifier: String?
    var secureFocused: Binding<Bool>?

    @State var shake = false
    var shakeOnInvalid = true

    var isValidText: ((String) -> Bool)?

    init(placeholder: String = "", multiline: Bool = false, font: Font = .themeBody, text: Binding<String>, secured: Binding<Bool> = .constant(false), isValidText: ((String) -> Bool)? = nil) {
        self.placeholder = placeholder
        self.multiline = multiline
        self.font = font
        self.text = text
        _secured = secured

        self.isValidText = isValidText
    }

    var body: some View {
        let view = editView()
            .font(font)
            .tint(.themeInputFieldTintColor)
            .accentColor(.themeLeah)

        if let isValidText {
            view.modifier(Validated(text: text, isValidText: isValidText))
        } else {
            view
        }
    }

    @ViewBuilder
    func editView() -> some View {
        if secureToggleEnabled {
            MaskedInputTextFieldView(
                placeholder: placeholder,
                text: text,
                secured: $secured,
                isEnabled: isEnabled,
                placeholderColor: isInsideThemeInput ? .themeAndy : .themeGray50,
                identifier: secureIdentifier,
                isFocused: secureFocused
            )
            .frame(height: 20) // TODO: How to remove this? (When change from Secure to TextField it's change height)
        } else if isInsideThemeInput {
            if multiline {
                TextField(
                    placeholder,
                    text: text,
                    prompt: prompt,
                    axis: .vertical
                )
                .foregroundColor(isEnabled ? .themeLeah : .themeAndy)
            } else {
                TextField(
                    placeholder,
                    text: text,
                    prompt: prompt
                )
                .foregroundColor(isEnabled ? .themeLeah : .themeAndy)
                .frame(height: 20) // TODO: How to remove this? (When change from Secure to TextField it's change height)
            }
        } else {
            if #available(iOS 16.0, *), multiline {
                TextField(
                    placeholder,
                    text: text,
                    axis: .vertical
                )
                .accentColor(.themeBrand)
                .foregroundColor(isEnabled ? .themeLeah : .themeAndy)
            } else {
                TextField(
                    placeholder,
                    text: text
                )
                .accentColor(.themeBrand)
                .foregroundColor(isEnabled ? .themeLeah : .themeAndy)
                .frame(height: 20) // TODO: How to remove this? (When change from Secure to TextField it's change height)
            }
        }
    }

    private var prompt: Text {
        Text(placeholder).foregroundColor(.themeAndy)
    }
}

extension InputTextView {
    /// `isFocused` replaces `.focused(...)` for the masked field, which `@FocusState` cannot track
    func secure(_ secured: Binding<Bool>, identifier: String? = nil, isFocused: Binding<Bool>? = nil) -> InputTextView {
        var selfView = self
        selfView._secured = secured
        selfView.secureToggleEnabled = true
        selfView.secureIdentifier = identifier
        selfView.secureFocused = isFocused
        return selfView
    }
}

struct ColoredBorder: ViewModifier {
    let cornerRadius: CGFloat
    let color: Color

    init(cornerRadius: CGFloat = .cornerRadius12, color: Color = .themeBrand) {
        self.cornerRadius = cornerRadius
        self.color = color
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(color, lineWidth: .heightOneDp)
            )
    }
}

struct Validated: ViewModifier {
    let text: Binding<String>
    let isValidText: ((String) -> Bool)?
    let shakeOnInvalid: Bool

    @State private var oldValue: String
    @State private var shake = false

    init(text: Binding<String>, shakeOnInvalid: Bool = true, isValidText: ((String) -> Bool)? = nil) {
        self.text = text
        self.isValidText = isValidText
        self.shakeOnInvalid = shakeOnInvalid

        oldValue = text.wrappedValue
    }

    func body(content: Content) -> some View {
        content
            .onReceive(text.wrappedValue.publisher.collect()) {
                let newValue = $0.map { String($0) }.joined()
                if isValidText?(newValue) ?? true {
                    oldValue = newValue
                } else {
                    text.wrappedValue = oldValue

                    if shakeOnInvalid {
                        shake = true
                    }
                }
            }
            .shake($shake)
    }
}

import SwiftUI

struct InputTextView: View {
    var placeholder: String = ""
    var multiline: Bool
    var font: Font

    var text: Binding<String>

    @Environment(\.isEnabled) private var isEnabled
    @Binding var secured: Bool

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
        editView()
            .font(font)
            .accentColor(.themeLeah)
            .modifier(Validated(text: text, isValidText: isValidText))
    }

    @ViewBuilder
    func editView() -> some View {
        if secured {
            SecureField(
                placeholder,
                text: text
            )
            .textContentType(.oneTimeCode) // the only way to disable strong password suggestions
            .accentColor(.themeYellow)
            .frame(height: 20) // TODO: How to remove this? (When change from Secure to TextField it's change height)
        } else {
            if #available(iOS 16.0, *), multiline {
                TextField(
                    placeholder,
                    text: text,
                    axis: .vertical
                )
                .accentColor(.themeYellow)
                .foregroundColor(isEnabled ? .themeLeah : .themeAndy)
            } else {
                TextField(
                    placeholder,
                    text: text
                )
                .accentColor(.themeYellow)
                .foregroundColor(isEnabled ? .themeLeah : .themeAndy)
                .frame(height: 20) // TODO: How to remove this? (When change from Secure to TextField it's change height)
            }
        }
    }
}

extension InputTextView {
    func secure(_ secured: Binding<Bool>) -> some View {
        var selfView = self
        selfView._secured = secured

        return HStack(spacing: .margin16) {
            selfView

            Button(action: {
                secured.wrappedValue.toggle()
            }) {
                Image(secured.wrappedValue ? "eye_off_20" : "eye_20").themeIcon()
            }
        }
    }
}

struct ColoredBorder: ViewModifier {
    let cornerRadius: CGFloat
    let color: Color

    init(cornerRadius: CGFloat = InputView.cornerRadius, color: Color = .themeJacob) {
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

struct CautionBorder: ViewModifier {
    let cornerRadius: CGFloat
    @Binding var cautionState: CautionState

    init(cornerRadius: CGFloat = InputView.cornerRadius, cautionState: Binding<CautionState>) {
        self.cornerRadius = cornerRadius
        _cautionState = cautionState
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(cautionState.color, lineWidth: .heightOneDp)
            )
    }
}

struct FieldCautionBorder: ViewModifier {
    let cornerRadius: CGFloat
    @Binding var cautionState: FieldCautionState

    init(cornerRadius: CGFloat = InputView.cornerRadius, cautionState: Binding<FieldCautionState>) {
        self.cornerRadius = cornerRadius
        _cautionState = cautionState
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(cautionState.color, lineWidth: .heightOneDp)
            )
    }
}

struct CautionPrompt: ViewModifier {
    @Binding var cautionState: CautionState

    func body(content: Content) -> some View {
        VStack {
            content

            if let caution = cautionState.caution {
                Text(caution.text)
                    .themeCaption(color: cautionState.color)
            }
        }
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

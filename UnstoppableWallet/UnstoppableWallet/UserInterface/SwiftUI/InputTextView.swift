import SwiftUI
import ThemeKit

struct InputTextView: View {
    var placeholder: String = ""

    var text: Binding<String>
    @State private var oldValue: String

    @Binding var secured: Bool

    @State var shake = false
    var shakeOnInvalid = true

    var onEditingChanged: ((Bool) -> Void)?
    var onCommit: (() -> Void)?
    var isValidText: ((String) -> Bool)?

    init(placeholder: String = "", text: Binding<String>, secured: Binding<Bool> = .constant(false), onEditingChanged: ((Bool) -> Void)? = nil, onCommit: (() -> Void)? = nil, isValidText: ((String) -> Bool)? = nil) {
        self.placeholder = placeholder
        self.text = text
        oldValue = text.wrappedValue
        self._secured = secured

        self.onEditingChanged = onEditingChanged
        self.onCommit = onCommit
        self.isValidText = isValidText
    }

    var body: some View {
        editView()
            .font(.themeBody)
            .accentColor(.themeLeah)
            .frame(height: 20)      //todo: How to remove this?
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

    @ViewBuilder
    func editView() -> some View {
        if secured {
            SecureField(
                placeholder,
                text: text,
                onCommit: { commit() }
            )
            .accentColor(.themeYellow)
        } else {
            TextField(
                placeholder,
                text: text,
                onEditingChanged: { editingChanged($0) },
                onCommit: { commit() }
            )
            .accentColor(.themeYellow)
        }
    }

    private func editingChanged(_ bool: Bool) {
        onEditingChanged?(bool)
    }

    private func commit() {
        onCommit?()
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

struct CautionBorder: ViewModifier {
    let cornerRadius: CGFloat
    @Binding var cautionState: CautionState

    init(cornerRadius: CGFloat = .cornerRadius8, cautionState: Binding<CautionState>) {
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

import SwiftUI

struct InputCard: View {
    let title: LocalizedStringResource
    @Binding var text: String
    var customButton: CustomButton? = nil
    var focus: FocusState<Bool>.Binding

    var body: some View {
        ThemeCard(borderColor: focus.wrappedValue ? .themeLime : nil) {
            VStack(alignment: .leading, spacing: 10) {
                ThemeText(key: title, style: .captionSB, color: .themeGray)

                HStack(alignment: .center, spacing: 8) {
                    TextField(String(""), text: $text)
                        .font(TextStyle.headline1.font)
                        .foregroundColor(.themeLeah)
                        .focused(focus)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 32)

                    if focus.wrappedValue, !text.isEmpty {
                        IconButton(icon: "trash", style: .secondary, size: .small) {
                            text = ""
                        }
                    } else if let customButton {
                        IconButton(icon: customButton.icon, style: .secondary, size: .small) {
                            customButton.action()
                        }
                    }
                }
            }
        }
        .onTapGesture {
            focus.wrappedValue = true
        }
        .animation(.easeInOut(duration: 0.2), value: focus.wrappedValue)
    }
}

extension InputCard {
    struct CustomButton {
        let icon: String
        let action: () -> Void
    }
}

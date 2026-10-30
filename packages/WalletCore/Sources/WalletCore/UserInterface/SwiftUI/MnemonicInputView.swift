import SwiftUI

struct MnemonicInputView: View {
    let placeholder: String
    @Binding var value: CaretText
    let invalidRanges: [NSRange]
    var borderColor: Color = .themeBlade
    @Binding var isFocused: Bool
    let statPage: StatPage
    let statEntity: StatEntity

    var body: some View {
        VStack(spacing: .margin8) {
            ZStack(alignment: .topLeading) {
                if value.text.isEmpty {
                    ThemeText(placeholder, style: .body, colorStyle: .andy)
                }

                MnemonicTextView(value: $value, invalidRanges: invalidRanges, isFocused: $isFocused)
            }

            HStack(spacing: .margin8) {
                Spacer()

                if value.text.isEmpty {
                    IconButton(icon: "scan", style: .secondary, size: .small) {
                        Coordinator.shared.present { isPresented in
                            ScanQrView(options: [.picker], isPresented: isPresented) { text in
                                value = .end(text)
                                stat(page: statPage, event: .scanQr(entity: statEntity))
                            }
                            .ignoresSafeArea()
                        }
                    }

                    ThemeButton(text: "button.paste".localized, style: .secondary, size: .small) {
                        if let string = UIPasteboard.general.string {
                            value = .end(string)
                            stat(page: statPage, event: .paste(entity: statEntity))
                        }
                    }
                } else {
                    IconButton(icon: "trash", style: .secondary, size: .small) {
                        value = .end("")
                    }
                }
            }
            .animation(.default, value: value.text.isEmpty)
        }
        .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin12, trailing: .margin16))
        .background(RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous).fill(Color.themeLawrence))
        .overlay(RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous).stroke(borderColor, lineWidth: .heightOneDp))
    }
}

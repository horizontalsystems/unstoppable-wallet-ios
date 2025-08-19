import SwiftUI

struct LargeTextField: View {
    let placeholder: String
    @Binding var text: String
    let statPage: StatPage
    let statEntity: StatEntity

    var body: some View {
        VStack(spacing: .margin8) {
            TextField(
                placeholder,
                text: $text,
                axis: .vertical
            )
            .lineLimit(3...)
            .autocorrectionDisabled()
            .font(TextStyle.body.font)
            .accentColor(.themeLeah)

            HStack(spacing: .margin8) {
                Spacer()

                if text.isEmpty {
                    IconButton(icon: "scan", style: .secondary, size: .small) {
                        Coordinator.shared.present { _ in
                            ScanQrViewNew { text in
                                self.text = text
                                stat(page: statPage, event: .scanQr(entity: statEntity))
                            }
                            .ignoresSafeArea()
                        }
                    }

                    ThemeButton(text: "button.paste".localized, style: .secondary, size: .small) {
                        if let string = UIPasteboard.general.string {
                            text = string
                            stat(page: statPage, event: .paste(entity: statEntity))
                        }
                    }
                } else {
                    IconButton(icon: "trash", style: .secondary, size: .small) {
                        text = ""
                    }
                }
            }
        }
        .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin12, trailing: .margin16))
        .background(RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous).fill(Color.themeLawrence))
        .overlay(RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous).stroke(Color.themeBlade, lineWidth: .heightOneDp))
    }
}

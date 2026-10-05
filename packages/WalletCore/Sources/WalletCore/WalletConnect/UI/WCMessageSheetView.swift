import SwiftUI

// Full message text over the sign sheet; content sizes the sheet, as every other bottom sheet here
struct WCMessageSheetView: View {
    let text: String
    @Binding var isPresented: Bool

    var body: some View {
        BottomSheetView(items: [
            .title(title: "wallet_connect.sign.message".localized),
            .custom(view: AnyView(
                Text(text)
                    .themeSubhead2(color: .themeLeah, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(.margin16)
                    .overlay(
                        RoundedRectangle(cornerRadius: .cornerRadius16, style: .continuous)
                            .stroke(Color.themeBlade, lineWidth: .heightOneDp)
                    )
                    .padding(.horizontal, .margin16)
                    .padding(.top, .margin16)
                    .padding(.bottom, .margin16)
            )),
            .buttonGroup(.init(buttons: [
                .init(style: .gray, title: "button.back".localized) {
                    isPresented = false
                },
            ])),
        ])
    }
}

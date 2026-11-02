import MarketKit
import SwiftUI

struct TonConnectErrorView: View {
    let requestError: TonConnectSendTransactionRequestError

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                BottomGradientWrapper {
                    VStack {
                        AlertCardView(.init(text: "ton_connect.invalid_transaction".localized, type: .critical, style: .inline))
                        Spacer()
                    }
                    .padding(.top, .margin12)
                    .padding(.horizontal, .margin16)
                } bottomContent: {
                    ThemeButton(text: "button.close".localized, style: .secondary) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationTitle(requestError.app.manifest.name)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

import ComponentKit
import MarketKit
import SwiftUI

struct TonConnectErrorView: View {
    let requestError: TonConnectSendTransactionRequestError

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ThemeNavigationView {
            ThemeView {
                BottomGradientWrapper {
                    VStack {
                        HighlightedTextView(text: "ton_connect.invalid_transaction".localized, style: .alert)
                        Spacer()
                    }
                    .padding(.top, .margin12)
                    .padding(.horizontal, .margin16)
                } bottomContent: {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("button.close".localized)
                    }
                    .buttonStyle(PrimaryButtonStyle(style: .gray))
                }
            }
            .navigationTitle(requestError.app.manifest.name)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

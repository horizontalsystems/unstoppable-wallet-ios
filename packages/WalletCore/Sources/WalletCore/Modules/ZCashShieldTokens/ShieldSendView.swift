
import MarketKit
import SwiftUI
import ZcashLightClientKit

struct ShieldSendView: View {
    private let sendData: SendData
    private let onSuccess: (() -> Void)?

    @Environment(\.presentationMode) private var presentationMode

    init(amount: Decimal, address: String?, onSuccess: (() -> Void)? = nil) {
        let recipient = address.flatMap { try? Recipient($0, network: ZcashAdapter.networkType) }

        sendData = .zcashShield(amount: amount, recipient: recipient, memo: nil)
        self.onSuccess = onSuccess
    }

    var body: some View {
        ThemeView {
            RegularSendView(sendData: sendData, title: "send.confirmation.shield_title".localized) {
                HudHelper.instance.show(banner: .sent)
                presentationMode.wrappedValue.dismiss()
                onSuccess?()
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image("close")
                }
            }
        }
    }
}

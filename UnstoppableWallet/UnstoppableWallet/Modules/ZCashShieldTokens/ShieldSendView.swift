import ComponentKit
import MarketKit
import SwiftUI
import ZcashLightClientKit

struct ShieldSendView: View {
    private let sendData: SendData

    @Environment(\.presentationMode) private var presentationMode
    
    init(amount: Decimal, address: String?) {
        let recipient = address.flatMap { try? Recipient.init($0, network: .mainnet) }
        
        sendData = .zcashShield(amount: amount, recipient: recipient, memo: nil)
    }

    var body: some View {
        ThemeView {
            RegularSendView(sendData: sendData) {
                HudHelper.instance.show(banner: .sent)
                presentationMode.wrappedValue.dismiss()
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("button.cancel".localized) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

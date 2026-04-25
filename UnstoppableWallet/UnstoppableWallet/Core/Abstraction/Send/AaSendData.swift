import EvmKit
import Foundation
import MarketKit
import SwiftUI

class AaSendData: ISendData {
    let prepared: PreparedUserOp
    let baseToken: Token

    init(prepared: PreparedUserOp, baseToken: Token) {
        self.prepared = prepared
        self.baseToken = baseToken
    }

    var feeData: FeeData? {
        // v1: nil suppresses the "Edit Fee" menu item in SendView (FeeSettingsViewFactory has
        // no AA case yet; non-nil here would surface a dangling action). Fee mode is shown as
        // a row in `sections(...)` instead.
        nil
    }

    var canSend: Bool {
        // AaSender.prepare() throws on any RPC / paymaster / signing failure; reaching here
        // means the UserOp is fully assembled. v1 has no further validation step.
        true
    }

    var rateCoins: [Coin] {
        prepared.decoration.rateCoins
    }

    func cautions(baseToken _: Token, currency _: Currency, rates _: [String: Decimal]) -> [CautionNew] {
        // RPC / paymaster failures throw before AaSendData is constructed.
        []
    }

    func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
        let flow = prepared.decoration.flowSection(baseToken: baseToken, currency: currency, rates: rates)
        var fields = prepared.decoration.fields(baseToken: baseToken, currency: currency, rates: rates)

        let feeValue = prepared.paymasterMode.isSponsored
            ? "send.confirmation.fee_sponsored".localized
            : "send.confirmation.fee_paid_in".localized(baseToken.coin.code)
        fields.append(.simpleValue(
            title: "send.network_fee".localized,
            value: feeValue
        ))

        if prepared.isFreshDeployment {
            fields.append(.note(iconName: "info_24", title: "send.confirmation.aa_first_deploy".localized))
        }

        return [flow, .init(fields, isMain: false)].compactMap { $0 }
    }
}

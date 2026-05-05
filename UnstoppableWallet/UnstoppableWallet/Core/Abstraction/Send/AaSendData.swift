import BigInt
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
        // no AA case yet; non-nil here would surface a dangling action). Fee rows are emitted
        // in `sections(...)` instead.
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

        let breakdown = prepared.feeBreakdown
        let feeTokenRate = rates[baseToken.coin.uid]

        fields.append(.fee(
            title: ComponentInformedTitle("send.fee.estimated".localized, info: .fee),
            amountData: amountData(rawTokenAmount: breakdown.estimatedFeeInToken, baseToken: baseToken, currency: currency, feeTokenRate: feeTokenRate)
        ))

        fields.append(.fee(
            title: ComponentInformedTitle("send.fee.max_required".localized, info: .fee),
            amountData: amountData(rawTokenAmount: breakdown.requiredPrefundInToken, baseToken: baseToken, currency: currency, feeTokenRate: feeTokenRate)
        ))

        switch breakdown.scenario {
        case .freshDeploy:
            fields.append(.note(iconName: nil, title: "send.fee.includes_activation_approval".localized))
        case .approveAndSend:
            fields.append(.note(iconName: nil, title: "send.fee.includes_approval".localized))
        case .approvedSend:
            ()
        }

        return [flow, .init(fields, isMain: false)].compactMap { $0 }
    }

    private func amountData(rawTokenAmount: BigUInt, baseToken: Token, currency: Currency, feeTokenRate: Decimal?) -> AmountData? {
        guard let amount = Decimal(bigUInt: rawTokenAmount, decimals: baseToken.decimals) else {
            return nil
        }

        let appValue = AppValue(token: baseToken, value: amount)
        let currencyValue = feeTokenRate.map { CurrencyValue(currency: currency, value: amount * $0) }

        return AmountData(appValue: appValue, currencyValue: currencyValue)
    }
}

import Foundation
import MarketKit

// Wraps the chain handler's send data: the verdict gates the confirm button and adds its banner
class WCNSendData: ISendData {
    let inner: ISendData
    private let request: WCNRequest

    init(inner: ISendData, request: WCNRequest) {
        self.inner = inner
        self.request = request
    }

    var feeData: FeeData? { inner.feeData }
    var canSend: Bool { inner.canSend && !request.isBlocked }
    var rateCoins: [Coin] { inner.rateCoins }
    var amountAdjusted: Bool { inner.amountAdjusted }

    var customSendButtonTitle: String? {
        request.parsed.isSignOnly ? "button.sign".localized : inner.customSendButtonTitle
    }

    func feeFields(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendField] {
        inner.feeFields(baseToken: baseToken, currency: currency, rates: rates)
    }

    func cautions(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [CautionNew] {
        let innerCautions = inner.cautions(baseToken: baseToken, currency: currency, rates: rates)

        switch request.verdict {
        case .pass: return innerCautions
        case let .caution(reason): return innerCautions + [CautionNew(text: reason, type: .warning)]
        case let .block(reason): return innerCautions + [CautionNew(text: reason, type: .error)]
        }
    }

    func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
        let dAppSection = SendDataSection([.simpleValue(title: "wallet_connect.sign.dapp_name".localized, value: request.dAppName)], isMain: false)
        return inner.sections(baseToken: baseToken, currency: currency, rates: rates) + [dAppSection]
    }
}

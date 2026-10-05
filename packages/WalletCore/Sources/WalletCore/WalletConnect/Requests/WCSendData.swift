import Foundation
import MarketKit

// Wraps the chain handler's send data: the verdict gates the confirm button and adds its banner
class WCSendData: ISendData {
    let inner: ISendData
    private let request: WCRequest
    private let header: WCSendHeader?
    private let accountName: String?

    init(inner: ISendData, request: WCRequest, header: WCSendHeader? = nil, accountName: String? = nil) {
        self.inner = inner
        self.request = request
        self.header = header
        self.accountName = accountName
    }

    var feeData: FeeData? { inner.feeData }
    var canSend: Bool { inner.canSend && !request.isBlocked && !request.isExpired }
    var rateCoins: [Coin] { inner.rateCoins }
    var amountAdjusted: Bool { inner.amountAdjusted }

    var customSendButtonTitle: String? {
        request.payload.isSignOnly ? "button.sign".localized : inner.customSendButtonTitle
    }

    func feeFields(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendField] {
        inner.feeFields(baseToken: baseToken, currency: currency, rates: rates)
    }

    func cautions(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [CautionNew] {
        let innerCautions = inner.cautions(baseToken: baseToken, currency: currency, rates: rates)

        switch request.verdict {
        case .pass: return innerCautions
        case let .caution(reason): return innerCautions + [CautionNew(text: reason.text, type: .warning)]
        case let .block(reason): return innerCautions + [CautionNew(text: reason.text, type: .error)]
        }
    }

    // header, then one card: the chain rows, network, wallet and fee, as Android WCSendEthScreen
    func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
        let signOnly = request.payload.isSignOnly
        let headerField = WCSendHeaderField(
            iconUrl: request.dAppIconUrl,
            title: header?.title ?? (signOnly ? "wallet_connect.sign.request_title" : "wallet_connect.transaction.title").localized,
            host: request.dAppUrl.map { URLComponents(string: $0)?.host ?? $0 } ?? request.dAppName,
            description: header?.description ?? (signOnly ? "wallet_connect.sign_transaction.description".localized(request.dAppName) : nil)
        )

        var fields = inner.sections(baseToken: baseToken, currency: currency, rates: rates).flatMap(\.fields)
        fields.append(.simpleValue(title: "wallet_connect.sign.network".localized, value: baseToken.blockchain.name))
        if let accountName {
            fields.append(.simpleValue(title: "wallet_connect.connect.wallet".localized, value: accountName))
        }
        fields.append(contentsOf: inner.feeFields(baseToken: baseToken, currency: currency, rates: rates))

        return [SendDataSection([SendField(headerField)], isList: false), SendDataSection(fields, isMain: false)]
    }
}

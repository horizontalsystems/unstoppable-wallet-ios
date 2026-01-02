import Foundation
import MarketKit

protocol ISendData {
    var feeData: FeeData? { get }
    var canSend: Bool { get }
    var rateCoins: [Coin] { get }
    var customSendButtonTitle: String? { get }
    func cautions(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [CautionNew]
    func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection]
}

extension ISendData {
    var customSendButtonTitle: String? {
        nil
    }

    func flowSection(baseToken _: Token, currency _: Currency, rates _: [String: Decimal]) -> (SendField, SendField)? {
        nil
    }
}

class SendDataSection {
    let fields: [SendField]
    let isMain: Bool
    let isFlow: Bool
    let isList: Bool

    init(_ fields: [SendField], isMain: Bool = true, isFlow: Bool = false, isList: Bool = true) {
        self.fields = fields
        self.isMain = isMain
        self.isFlow = isFlow
        self.isList = isList
    }
}

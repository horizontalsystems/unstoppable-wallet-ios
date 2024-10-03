import Foundation
import MarketKit

protocol ISendData {
    var feeData: FeeData? { get }
    var canSend: Bool { get }
    var rateCoins: [Coin] { get }
    var customSendButtonTitle: String? { get }
    func cautions(baseToken: Token) -> [CautionNew]
    func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [[TransactionField]]
}

extension ISendData {
    var customSendButtonTitle: String? {
        nil
    }
}

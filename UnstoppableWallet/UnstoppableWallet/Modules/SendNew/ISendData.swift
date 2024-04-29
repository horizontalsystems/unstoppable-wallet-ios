import Foundation
import MarketKit

protocol ISendData {
    var feeData: FeeData? { get }
    var canSend: Bool { get }
    var sendButtonTitle: String { get }
    var sendingButtonTitle: String { get }
    var sentButtonTitle: String { get }
    func cautions(baseToken: Token) -> [CautionNew]
    func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [[SendField]]
}

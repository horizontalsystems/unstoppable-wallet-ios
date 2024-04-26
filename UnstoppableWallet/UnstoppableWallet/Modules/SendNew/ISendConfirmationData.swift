import Foundation
import MarketKit

protocol ISendConfirmationData {
    var feeData: FeeData? { get }
    var canSend: Bool { get }
    var sendButtonTitle: String { get }
    var sendingButtonTitle: String { get }
    var sentButtonTitle: String { get }
    func sections(feeToken: Token?, currency: Currency, feeTokenRate: Decimal?) -> [[SendConfirmField]]
    func cautions(feeToken: Token?) -> [CautionNew]
}

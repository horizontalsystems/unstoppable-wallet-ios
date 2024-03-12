import Foundation
import MarketKit

protocol ISendConfirmationData {
    var feeData: FeeData? { get }
    var canSend: Bool { get }
    var customSendButtonTitle: String? { get }
    var customSendingButtonTitle: String? { get }
    func cautions(feeToken: Token?) -> [CautionNew]
    func sections(feeToken: Token?, currency: Currency, feeTokenRate: Decimal?) -> [[SendConfirmField]]
}

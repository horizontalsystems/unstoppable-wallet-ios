import Foundation
import MarketKit

protocol ISendConfirmationData {
    var feeData: FeeData? { get }
    var canSend: Bool { get }
    func cautions(feeToken: Token?) -> [CautionNew]
    func sections(feeToken: Token?, currency: Currency, feeTokenRate: Decimal?) -> [[SendConfirmField]]
}

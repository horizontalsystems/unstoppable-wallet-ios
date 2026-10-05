import BitcoinCore
import Foundation
import ZcashLightClientKit

class ZcashSendHelper {
    static func converted(_ error: Error) -> Error {
        switch error as? ZcashLightClientKit.ZcashError {
        case .rustProposalInsufficientFunds:
            return BitcoinCoreErrors.SendValueErrors.notEnough
        case .rustProposalScanRequired:
            return AppError.zcash(reason: .syncRequired)
        default:
            return error
        }
    }
}

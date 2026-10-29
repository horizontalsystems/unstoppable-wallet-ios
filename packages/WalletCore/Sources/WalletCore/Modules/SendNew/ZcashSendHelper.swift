import BitcoinCore
import Foundation
import ZODLSwiftWalletSDK

class ZcashSendHelper {
    static func converted(_ error: Error) -> Error {
        switch error as? ZODLSwiftWalletSDK.ZcashError {
        case .rustProposalInsufficientFunds:
            return BitcoinCoreErrors.SendValueErrors.notEnough
        case .rustProposalScanRequired:
            return AppError.zcash(reason: .syncRequired)
        default:
            return error
        }
    }
}

import BitcoinCore
import Foundation
import ZcashLightClientKit

class ZcashSendHelper {
    private static let insufficientBalanceError = "insufficient balance"

    static func converted(_ error: Error) -> Error {
        var errorText: String?
        if case let .rustProposeTransferFromURI(text) = error as? ZcashLightClientKit.ZcashError {
            errorText = text
        }

        if case let .rustCreateToAddress(text) = error as? ZcashLightClientKit.ZcashError {
            errorText = text
        }

        if errorText?.range(of: Self.insufficientBalanceError, options: .caseInsensitive) != nil {
            return BitcoinCoreErrors.SendValueErrors.notEnough
        }

        return error
    }
}

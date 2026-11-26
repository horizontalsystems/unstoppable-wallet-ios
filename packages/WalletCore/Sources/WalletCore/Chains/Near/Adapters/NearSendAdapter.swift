import Foundation
import NearKit

protocol ISendNearAdapter {
    var address: String { get }
    var fee: Decimal { get }
    var availableNear: Decimal { get }
    var pendingTransactionHashes: Set<String> { get }
    func estimate(address: String, amount: Decimal, memo: String?) async throws -> NearSendEstimate
    func send(amount: Decimal, address: String, memo: String?, estimate: NearSendEstimate, signer: NearKit.Signer) async throws -> String
}

// requiredNear: the NEAR balance the network needs to accept the send, well above the fee because gas is bought up front
struct NearSendEstimate {
    let fee: Decimal
    let storageDeposit: Decimal?
    let requiredNear: Decimal
    let ftTransferEstimate: FtTransferEstimate?
}

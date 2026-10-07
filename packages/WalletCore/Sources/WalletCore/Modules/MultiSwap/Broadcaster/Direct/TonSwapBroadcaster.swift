import Foundation
import MarketKit
import TonKit

class TonSwapBroadcaster: ISwapBroadcaster {
    private let account: Account
    private let adapterManager: AdapterManager

    init(account: Account, adapterManager: AdapterManager) {
        self.account = account
        self.adapterManager = adapterManager
    }

    func prepare(_ executable: ISwapExecutable) async throws -> IPrepared {
        DirectPrepared(executable: executable)
    }

    func submit(_ prepared: IPrepared) async throws -> BroadcastResult {
        guard let prepared = prepared as? DirectPrepared, let executable = prepared.executable as? TonExecutable else {
            throw SwapBroadcasterError.dataMismatch
        }
        guard let kind = executable.kind else {
            throw MultiSwapSendHandler.SendError.invalidTransactionData
        }

        let (publicKey, secretKey) = try TonKitManager.keyPair(accountType: account.type)
        let contract = TonKitManager.contract(publicKey: publicKey)

        let transferData: TransferData

        switch kind {
        case let .param(param):
            transferData = try TonSendHelper.transferData(param: param, contract: contract)
        case let .transfer(transfer):
            guard let adapter = adapterManager.adapter(for: executable.token) as? ISendTonAdapter else {
                throw MultiSwapSendHandler.SendError.noTonAdapter
            }

            transferData = try adapter.transferData(
                recipient: transfer.recipient,
                amount: .amount(value: transfer.amount),
                comment: transfer.comment
            )
        }

        // the TEP-467 normalized hash is derived before the send, so nothing throws after broadcast
        let txHash = try await TonSendHelper.sendReturningHash(
            transferData: transferData,
            contract: contract,
            secretKey: secretKey
        )

        return BroadcastResult(txHash: txHash, trackingHandle: nil)
    }
}

extension TonSwapBroadcaster: ISwapBroadcasterType {
    static func make(blockchainType: BlockchainType, account: Account) -> ISwapBroadcaster? {
        guard blockchainType == .ton else {
            return nil
        }

        return TonSwapBroadcaster(account: account, adapterManager: Core.shared.adapterManager)
    }
}

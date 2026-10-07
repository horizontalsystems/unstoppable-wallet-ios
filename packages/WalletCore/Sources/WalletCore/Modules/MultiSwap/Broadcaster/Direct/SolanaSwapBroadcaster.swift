import Foundation
import MarketKit
import SolanaKit

class SolanaSwapBroadcaster: ISwapBroadcaster {
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
        guard let prepared = prepared as? DirectPrepared, let executable = prepared.executable as? SolanaExecutable else {
            throw SwapBroadcasterError.dataMismatch
        }

        let signer = try SolanaKitManager.signer(accountType: account.type)

        guard let adapter = adapterManager.adapter(for: executable.token) as? ISendSolanaAdapter else {
            throw MultiSwapSendHandler.SendError.noSolanaAdapter
        }

        guard let kind = executable.kind else {
            throw MultiSwapSendHandler.SendError.invalidTransactionData
        }

        let fullTransaction: SolanaKit.FullTransaction

        switch kind {
        case let .raw(rawTransaction):
            fullTransaction = try await adapter.sendRawTransaction(rawTransaction: rawTransaction, signer: signer)
        case let .transfer(transfer):
            switch executable.token.type {
            case .native:
                fullTransaction = try await adapter.sendSol(toAddress: transfer.toAddress, amount: transfer.amount, signer: signer)
            case let .spl(mintAddress):
                fullTransaction = try await adapter.sendSpl(
                    mintAddress: mintAddress,
                    toAddress: transfer.toAddress,
                    amount: transfer.amount,
                    decimals: executable.token.decimals,
                    signer: signer
                )
            default:
                throw MultiSwapSendHandler.SendError.invalidTransactionData
            }
        }

        return BroadcastResult(txHash: fullTransaction.transaction.hash, trackingHandle: nil)
    }
}

extension SolanaSwapBroadcaster: ISwapBroadcasterType {
    static func make(blockchainType: BlockchainType, account: Account) -> ISwapBroadcaster? {
        guard blockchainType == .solana else {
            return nil
        }

        return SolanaSwapBroadcaster(account: account, adapterManager: Core.shared.adapterManager)
    }
}

import EvmKit
import SwiftUI

enum EvmResendModule {
    static func present(adapter: ITransactionsAdapter, type: ResendTransactionType, transactionHash: String) throws {
        guard let adapter = adapter as? EvmTransactionsAdapter,
              let hash = transactionHash.hs.hexData,
              let fullTransaction = adapter.evmKit.transaction(hash: hash)
        else { throw EvmReplacementData.ValidationError.wrongTransaction }

        _ = try EvmResendHandler.prepare(
            transaction: fullTransaction.transaction, blockchainType: adapter.evmKitWrapper.blockchainType,
            receiveAddress: adapter.evmKit.receiveAddress,
            isProtected: MerkleTransactionAdapter.isProtected(transaction: fullTransaction), type: type
        )
        let sendData = SendData.evmResend(blockchainType: adapter.evmKitWrapper.blockchainType, transaction: fullTransaction.transaction, type: type)
        let viewModel = SendViewModel(sendData: sendData)
        guard viewModel.handler != nil else { throw EvmReplacementData.ValidationError.wrongTransaction }
        Coordinator.shared.present { isPresented in
            ThemeNavigationStack {
                EvmResendView(viewModel: viewModel, type: type) {
                    isPresented.wrappedValue = false
                }
            }
        }
    }
}

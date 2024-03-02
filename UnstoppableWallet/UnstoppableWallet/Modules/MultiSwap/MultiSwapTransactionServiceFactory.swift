import MarketKit

struct MultiSwapTransactionServiceFactory {
    private let evmBlockchainManager = App.shared.evmBlockchainManager

    func transactionService(blockchainType: BlockchainType) -> IMultiSwapTransactionService {
        if EvmBlockchainManager.blockchainTypes.contains(blockchainType),
           let evmKit = evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper?.evmKit,
           let transactionService = EvmMultiSwapTransactionService(blockchainType: blockchainType, userAddress: evmKit.receiveAddress)
        {
            return transactionService
        }

        fatalError("No transaction service for \(blockchainType.uid)")
    }
}

import MarketKit

struct TransactionServiceFactory {
    private let evmBlockchainManager = App.shared.evmBlockchainManager

    func transactionService(blockchainType: BlockchainType) -> ITransactionService? {
        if EvmBlockchainManager.blockchainTypes.contains(blockchainType),
           let evmKit = evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper?.evmKit,
           let transactionService = EvmTransactionService(blockchainType: blockchainType, userAddress: evmKit.receiveAddress)
        {
            return transactionService
        }

        return nil
    }
}

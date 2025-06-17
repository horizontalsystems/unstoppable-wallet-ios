import MarketKit

enum TransactionServiceFactory {
    static func transactionService(blockchainType: BlockchainType, initialTransactionSettings: InitialTransactionSettings?) -> ITransactionService? {
        if EvmBlockchainManager.blockchainTypes.contains(blockchainType),
           let evmKit = Core.shared.evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper?.evmKit,
           let transactionService = EvmTransactionService(blockchainType: blockchainType, userAddress: evmKit.receiveAddress, initialTransactionSettings: initialTransactionSettings)
        {
            return transactionService
        }

        if BtcBlockchainManager.blockchainTypes.contains(blockchainType) {
            return BitcoinTransactionService(blockchainType: blockchainType)
        }

        return nil
    }
}

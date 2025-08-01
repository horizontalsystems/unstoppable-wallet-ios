import MarketKit

enum TransactionServiceFactory {
    static func transactionService(blockchainType: BlockchainType, initialTransactionSettings: InitialTransactionSettings?) -> ITransactionService? {
        if EvmBlockchainManager.blockchainTypes.contains(blockchainType),
           let evmKit = Core.shared.evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper?.evmKit,
           let transactionService = EvmTransactionService(blockchainType: blockchainType, evmKit: evmKit, initialTransactionSettings: initialTransactionSettings)
        {
            return transactionService
        }

        if BtcBlockchainManager.blockchainTypes.contains(blockchainType) {
            return BitcoinTransactionService(blockchainType: blockchainType)
        }

        if blockchainType == .monero {
            return MoneroTransactionService()
        }

        return nil
    }
}

import MarketKit

enum TransactionServiceFactory {
    static func transactionService(blockchainType: BlockchainType) -> ITransactionService? {
        if EvmBlockchainManager.blockchainTypes.contains(blockchainType),
           let evmKit = App.shared.evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper?.evmKit,
           let transactionService = EvmTransactionService(blockchainType: blockchainType, userAddress: evmKit.receiveAddress)
        {
            return transactionService
        }

        if BtcBlockchainManager.blockchainTypes.contains(blockchainType) {
            return BitcoinTransactionService(blockchainType: blockchainType)
        }

        return nil
    }
}

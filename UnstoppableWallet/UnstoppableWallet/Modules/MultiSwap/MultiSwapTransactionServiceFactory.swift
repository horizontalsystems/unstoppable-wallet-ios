import MarketKit

struct MultiSwapTransactionServiceFactory {
    private let evmBlockchainManager = App.shared.evmBlockchainManager

    func transactionService(blockchainType: BlockchainType) -> IMultiSwapTransactionService? {
        if EvmBlockchainManager.blockchainTypes.contains(blockchainType),
           let evmKit = evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper?.evmKit
        {
            return EvmMultiSwapTransactionService(blockchainType: blockchainType, userAddress: evmKit.receiveAddress)
        }

        return nil
    }
}

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

struct SendHandlerFactory {
    func handler(sendData: SendDataNew) -> ISendHandler? {
        switch sendData {
        case let .evm(blockchainType, transactionData):
            return SendEvmHandler.instance(blockchainType: blockchainType, transactionData: transactionData)
        case .bitcoin:
            return nil
        }
    }
}

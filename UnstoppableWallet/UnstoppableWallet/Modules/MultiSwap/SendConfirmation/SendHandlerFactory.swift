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

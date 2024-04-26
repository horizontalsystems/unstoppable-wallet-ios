import MarketKit

enum SendHandlerFactory {
    static func handler(sendData: SendData) -> ISendHandler? {
        switch sendData {
        case let .evm(blockchainType, transactionData):
            return EvmSendHandler.instance(blockchainType: blockchainType, transactionData: transactionData)
        case .bitcoin:
            return nil
        case .swap:
            return nil
        }
    }

    static func preSendHandler(wallet: Wallet) -> IPreSendHandler? {
        if let adapter = App.shared.adapterManager.adapter(for: wallet) as? ISendEthereumAdapter {
            return EvmPreSendHandler(token: wallet.token, adapter: adapter)
        }

        return nil
    }
}

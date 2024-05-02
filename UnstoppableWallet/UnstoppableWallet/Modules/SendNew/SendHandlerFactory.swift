import MarketKit

enum SendHandlerFactory {
    static func handler(sendData: SendData) -> ISendHandler? {
        switch sendData {
        case let .evm(blockchainType, transactionData):
            return EvmSendHandler.instance(blockchainType: blockchainType, transactionData: transactionData)
        case let .bitcoin(token, params):
            return BitcoinSendHandler.instance(token: token, params: params)
        case let .swap(tokenIn, tokenOut, amountIn, provider):
            return MultiSwapSendHandler.instance(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, provider: provider)
        }
    }

    static func preSendHandler(wallet: Wallet) -> IPreSendHandler? {
        if let adapter = App.shared.adapterManager.adapter(for: wallet) as? ISendEthereumAdapter {
            return EvmPreSendHandler(token: wallet.token, adapter: adapter)
        }

        if let adapter = App.shared.adapterManager.adapter(for: wallet) as? BitcoinBaseAdapter {
            return BitcoinPreSendHandler(token: wallet.token, adapter: adapter)
        }

        return nil
    }
}

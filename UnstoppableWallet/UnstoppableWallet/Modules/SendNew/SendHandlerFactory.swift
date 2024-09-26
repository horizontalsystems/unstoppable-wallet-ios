import MarketKit

enum SendHandlerFactory {
    static func handler(sendData: SendData) -> ISendHandler? {
        switch sendData {
        case let .evm(blockchainType, transactionData):
            return EvmSendHandler.instance(blockchainType: blockchainType, transactionData: transactionData)
        case let .bitcoin(token, params):
            return BitcoinSendHandler.instance(token: token, params: params)
        case let .binance(token, amount, address, memo):
            return BinanceSendHandler.instance(token: token, amount: amount, address: address, memo: memo)
        case let .zcash(amount, recipient, memo):
            return ZcashSendHandler.instance(amount: amount, recipient: recipient, memo: memo)
        case let .tron(token, contract):
            return TronSendHandler.instance(token: token, contract: contract)
        case let .ton(token, amount, address, memo):
            return TonSendHandler.instance(token: token, amount: amount, address: address, memo: memo)
        case let .swap(tokenIn, tokenOut, amountIn, provider):
            return MultiSwapSendHandler.instance(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, provider: provider)
        case let .walletConnect(request):
            return WalletConnectSendHandler.instance(request: request)
        case let .tonConnect(request):
            return try? TonConnectSendHandler.instance(request: request)
        }
    }

    static func preSendHandler(wallet: Wallet) -> IPreSendHandler? {
        let adapter = App.shared.adapterManager.adapter(for: wallet)

        if let adapter = adapter as? ISendEthereumAdapter & IBalanceAdapter {
            return EvmPreSendHandler(token: wallet.token, adapter: adapter)
        }

        if let adapter = adapter as? BitcoinBaseAdapter {
            return BitcoinPreSendHandler(token: wallet.token, adapter: adapter)
        }

        if let adapter = adapter as? ISendBinanceAdapter & IBalanceAdapter {
            return BinancePreSendHandler(token: wallet.token, adapter: adapter)
        }

        if let adapter = adapter as? ISendZcashAdapter & IBalanceAdapter {
            return ZcashPreSendHandler(token: wallet.token, adapter: adapter)
        }

        if let adapter = adapter as? ISendTronAdapter & IBalanceAdapter {
            return TronPreSendHandler(token: wallet.token, adapter: adapter)
        }

        if let adapter = adapter as? ISendTonAdapter & IBalanceAdapter {
            return TonPreSendHandler(token: wallet.token, adapter: adapter)
        }

        return nil
    }
}

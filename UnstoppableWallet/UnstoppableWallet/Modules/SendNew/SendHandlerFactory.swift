import MarketKit

enum SendHandlerFactory {
    static func handler(sendData: SendData) -> ISendHandler? {
        switch sendData {
        case let .evm(blockchainType, transactionData):
            return EvmSendHandler.instance(blockchainType: blockchainType, transactionData: transactionData)
        case let .bitcoin(token, params):
            return BitcoinSendHandler.instance(token: token, params: params)
        case let .zcash(amount, recipient, memo):
            return ZcashSendHandler.instance(amount: amount, recipient: recipient, memo: memo)
        case let .zcashShield(amount, recipient, memo):
            return ShieldSendHandler.instance(amount: amount, recipient: recipient, memo: memo)
        case let .tron(token, contract):
            return TronSendHandler.instance(token: token, contract: contract)
        case let .ton(token, amount, address, memo):
            return TonSendHandler.instance(token: token, amount: amount, address: address, memo: memo)
        case let .stellar(data, token, memo):
            return StellarSendHandler.instance(data: data, token: token, memo: memo)
        case let .monero(token, amount, address, memo):
            return MoneroSendHandler.instance(token: token, amount: amount, address: address, memo: memo)
        case let .swap(tokenIn, tokenOut, amountIn, provider):
            return MultiSwapSendHandler.instance(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, provider: provider)
        case let .walletConnect(request):
            return WalletConnectSendHandler.instance(request: request)
        case let .tonConnect(request):
            return try? TonConnectSendHandler.instance(request: request)
        }
    }

    static func preSendHandler(wallet: Wallet, address: ResolvedAddress) -> IPreSendHandler? {
        let adapter = Core.shared.adapterManager.adapter(for: wallet)

        if let adapter = adapter as? ISendEthereumAdapter & IBalanceAdapter {
            return EvmPreSendHandler(token: wallet.token, adapter: adapter)
        }

        if let adapter = adapter as? BitcoinBaseAdapter {
            return BitcoinPreSendHandler(token: wallet.token, address: address, adapter: adapter)
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

        if let adapter = adapter as? StellarAdapter {
            return StellarPreSendHandler(token: wallet.token, adapter: adapter)
        }

        if let adapter = adapter as? MoneroAdapter {
            return MoneroPreSendHandler(token: wallet.token, adapter: adapter)
        }

        return nil
    }
}

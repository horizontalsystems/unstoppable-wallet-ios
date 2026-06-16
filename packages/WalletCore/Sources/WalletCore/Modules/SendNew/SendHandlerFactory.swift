import MarketKit

public enum SendHandlerFactory {
    private static var providers: [SendHandler.Type] = []
    private static var preSendProviders: [PreSendHandler.Type] = []

    public static func register(_ provider: SendHandler.Type) {
        providers.append(provider)
    }

    public static func register(_ provider: PreSendHandler.Type) {
        preSendProviders.append(provider)
    }

    public static func prepend(_ provider: SendHandler.Type) {
        providers.insert(provider, at: 0)
    }

    public static func prepend(_ provider: PreSendHandler.Type) {
        preSendProviders.insert(provider, at: 0)
    }

    static func handler(sendData: SendData) -> ISendHandler? {
        for provider in providers {
            if let handler = provider.instance(sendData: sendData) {
                return handler
            }
        }

        switch sendData {
        case let .walletConnect(request):
            return WalletConnectSendHandler.instance(request: request)
        case let .openCryptoPay(payment, entry, inner):
            return OpenCryptoPaySendHandlerFactory.handler(payment: payment, entry: entry, inner: inner)
        default:
            return nil
        }
    }

    public static func preSendHandler(wallet: Wallet, address: ResolvedAddress) -> IPreSendHandler? {
        for provider in preSendProviders {
            if let handler = provider.instance(wallet: wallet, address: address) {
                return handler
            }
        }

        return nil
    }
}

extension SendHandlerFactory {
    public static let unstoppableHandlers: [SendHandler.Type] = [
        EvmSendHandler.self,
        BitcoinSendHandler.self,
        ZcashSendHandler.self,
        ShieldSendHandler.self,
        TronSendHandler.self,
        TonSendHandler.self,
        StellarSendHandler.self,
        SolanaSendHandler.self,
        MoneroSendHandler.self,
        ZanoSendHandler.self,
        MultiSwapSendHandler.self,
        TonConnectSendHandler.self,
    ]

    public static let unstoppablePreSendHandlers: [PreSendHandler.Type] = [
        EvmPreSendHandler.self,
        BitcoinPreSendHandler.self,
        ZcashPreSendHandler.self,
        TronPreSendHandler.self,
        TonPreSendHandler.self,
        SolanaPreSendHandler.self,
        StellarPreSendHandler.self,
        MoneroPreSendHandler.self,
        ZanoPreSendHandler.self,
    ]
}

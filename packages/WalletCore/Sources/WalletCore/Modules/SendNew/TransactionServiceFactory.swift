import MarketKit

public enum TransactionServiceFactory {
    private static var providers: [TransactionService.Type] = []

    public static func register(_ provider: TransactionService.Type) {
        providers.append(provider)
    }

    public static func prepend(_ provider: TransactionService.Type) {
        providers.insert(provider, at: 0)
    }

    static func transactionService(sendData: SendData, baseToken: Token, initialTransactionSettings: InitialTransactionSettings?, feePriority: FeePriority = .standard) -> ITransactionService? {
        for provider in providers {
            if let service = provider.instance(sendData: sendData, baseToken: baseToken, initialTransactionSettings: initialTransactionSettings) {
                (service as? IFeePriorityConfigurable)?.set(feePriority: feePriority)
                return service
            }
        }

        return nil
    }
}

public extension TransactionServiceFactory {
    static let unstoppableTransactionServices: [TransactionService.Type] = [
        EvmTransactionService.self,
        BitcoinResendTransactionService.self,
        UtxoTransactionService.self,
        MoneroTransactionService.self,
        ZcashTransactionService.self,
    ]
}

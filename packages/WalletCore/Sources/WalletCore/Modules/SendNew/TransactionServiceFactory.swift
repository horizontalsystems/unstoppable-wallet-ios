import MarketKit

public enum TransactionServiceFactory {
    private static var providers: [TransactionService.Type] = []

    public static func register(_ provider: TransactionService.Type) {
        providers.append(provider)
    }

    public static func prepend(_ provider: TransactionService.Type) {
        providers.insert(provider, at: 0)
    }

    static func transactionService(sendData: SendData, baseToken: Token, initialTransactionSettings: InitialTransactionSettings?) -> ITransactionService? {
        for provider in providers {
            if let service = provider.instance(sendData: sendData, baseToken: baseToken, initialTransactionSettings: initialTransactionSettings) {
                return service
            }
        }

        return nil
    }
}

extension TransactionServiceFactory {
    public static let unstoppableTransactionServices: [TransactionService.Type] = [
        EvmTransactionService.self,
        UtxoTransactionService.self,
        MoneroTransactionService.self,
        ZcashTransactionService.self,
    ]
}

public protocol ITransactionsAdapterDecorator {
    static func decorate(adapter: ITransactionsAdapter, source: TransactionSource) -> ITransactionsAdapter?
}

public enum TransactionsAdapterDecoratorFactory {
    private static var providers: [ITransactionsAdapterDecorator.Type] = []

    public static func register(_ provider: ITransactionsAdapterDecorator.Type) {
        providers.append(provider)
    }

    public static func prepend(_ provider: ITransactionsAdapterDecorator.Type) {
        providers.insert(provider, at: 0)
    }

    static func decorate(adapter: ITransactionsAdapter, source: TransactionSource) -> ITransactionsAdapter {
        for provider in providers {
            if let decorated = provider.decorate(adapter: adapter, source: source) {
                return decorated
            }
        }

        return adapter
    }
}

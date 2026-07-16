import EvmKit
import MarketKit

// One FullTransaction → TransactionRecord converter in an app-assembled chain. nil → the next converter.
// `token` is the caller's scope — the pool token for list queries, nil for unscoped consumers
// (TransactionInfo live updates, SpamManager); a converter may shape the record per scope.
public protocol IEvmTransactionConverter {
    func convert(fullTransaction: FullTransaction, token: MarketKit.Token?) -> TransactionRecord?
}

// Supplies the converter chain for one adapter instance. Only the truly per-wallet context is passed:
// singletons (coinManager, evmLabelManager) are resolved inside WalletCore; the record TransactionSource is
// reconstructed from `baseToken` (EVM token types carry no source meta). nil → try the next provider.
public protocol IEvmTransactionConverterProvider {
    static func converters(baseToken: MarketKit.Token, userAddress: EvmKit.Address) -> [IEvmTransactionConverter]?
}

// Empty by default — every app registers a provider that supplies a converter chain for every EVM wallet,
// ending with a TOTAL converter (`defaultConverters`); mirrors EvmKitConfigFactory.
public enum EvmTransactionConverterFactory {
    private static var providers: [IEvmTransactionConverterProvider.Type] = []

    public static func register(_ provider: IEvmTransactionConverterProvider.Type) {
        providers.append(provider)
    }

    public static func prepend(_ provider: IEvmTransactionConverterProvider.Type) {
        providers.insert(provider, at: 0)
    }

    static func converters(baseToken: MarketKit.Token, userAddress: EvmKit.Address) -> [IEvmTransactionConverter] {
        for provider in providers {
            if let converters = provider.converters(baseToken: baseToken, userAddress: userAddress) {
                return converters
            }
        }

        // An empty chain silently breaks transaction history — a misconfiguration, never valid. Every app must
        // register a provider (EvmTransactionConverterFactory.register) that returns a chain for every EVM wallet.
        fatalError("EvmTransactionConverterFactory: no registered provider supplied converters for \(baseToken.blockchainType.uid)")
    }

    // The stock converter wired with the shared managers — public so an app chain composes or reuses it.
    public static func defaultConverter(baseToken: MarketKit.Token, userAddress: EvmKit.Address) -> EvmTransactionConverter {
        EvmTransactionConverter(
            baseToken: baseToken,
            coinManager: Core.shared.coinManager,
            userAddress: userAddress,
            evmLabelManager: Core.shared.evmLabelManager
        )
    }

    // The default chain — total: converts every FullTransaction.
    public static func defaultConverters(baseToken: MarketKit.Token, userAddress: EvmKit.Address) -> [IEvmTransactionConverter] {
        [defaultConverter(baseToken: baseToken, userAddress: userAddress)]
    }
}

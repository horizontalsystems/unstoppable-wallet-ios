import Eip20Kit
import EvmKit
import OneInchKit
import UniswapKit

public protocol IEvmKitConfigProvider {
    static func syncers(account: Account, evmKit: EvmKit.Kit) -> [ITransactionSyncer]?
    static func decorators(account: Account, evmKit: EvmKit.Kit)
}

public enum EvmKitConfigFactory {
    private static var providers: [IEvmKitConfigProvider.Type] = []

    public static func register(_ provider: IEvmKitConfigProvider.Type) {
        providers.append(provider)
    }

    public static func prepend(_ provider: IEvmKitConfigProvider.Type) {
        providers.insert(provider, at: 0)
    }

    static func syncers(account: Account, evmKit: EvmKit.Kit) -> [ITransactionSyncer] {
        for provider in providers {
            if let syncers = provider.syncers(account: account, evmKit: evmKit) {
                return syncers
            }
        }

        // An empty set silently disables ALL transaction sync — a misconfiguration, never valid. Every app must
        // register a provider (EvmKitConfigFactory.register) that returns a non-nil set for every EVM account.
        fatalError("EvmKitConfigFactory: no registered provider supplied syncers for account \(account.id)")
    }

    static func applyDecorators(account: Account, evmKit: EvmKit.Kit) {
        for provider in providers {
            provider.decorators(account: account, evmKit: evmKit)
        }
    }

    // The default base transaction syncers (ethereum + internal + eip20). Public so each app composes the set it
    // needs (or wraps it in its own syncer) instead of re-listing it. WalletCore registers NO provider itself —
    // every app sets its own syncers/decorators (no shared fallback).
    public static func defaultSyncers(evmKit: EvmKit.Kit) -> [ITransactionSyncer] {
        [evmKit.ethereumSyncer, evmKit.internalSyncer, Eip20Kit.Kit.transactionSyncer(for: evmKit)]
    }

    // The default EVM decorators (eip20 + uniswap v2/v3 + 1inch). Public so an app-side provider applies the set
    // it needs instead of re-listing it.
    public static func defaultDecorators(evmKit: EvmKit.Kit) {
        Eip20Kit.Kit.addDecorators(to: evmKit)
        UniswapKit.Kit.addDecorators(to: evmKit)
        try? KitV3.addDecorators(to: evmKit)
        OneInchKit.Kit.addDecorators(to: evmKit)
    }
}

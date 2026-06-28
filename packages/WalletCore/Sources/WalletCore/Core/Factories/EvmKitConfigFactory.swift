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

        return []
    }

    static func applyDecorators(account: Account, evmKit: EvmKit.Kit) {
        for provider in providers {
            provider.decorators(account: account, evmKit: evmKit)
        }
    }
}

enum UnstoppableEvmKitConfigProvider: IEvmKitConfigProvider {
    static func syncers(account _: Account, evmKit: EvmKit.Kit) -> [ITransactionSyncer]? {
        [evmKit.ethereumSyncer, evmKit.internalSyncer, Eip20Kit.Kit.transactionSyncer(for: evmKit)]
    }

    static func decorators(account _: Account, evmKit: EvmKit.Kit) {
        Eip20Kit.Kit.addDecorators(to: evmKit)
        UniswapKit.Kit.addDecorators(to: evmKit)
        try? KitV3.addDecorators(to: evmKit)
        OneInchKit.Kit.addDecorators(to: evmKit)
    }
}

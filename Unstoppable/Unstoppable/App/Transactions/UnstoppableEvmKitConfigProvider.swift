import EvmKit
import WalletCore

// App-side default EVM config for the Unstoppable app. Moved out of WalletCore (which now registers no provider
// — every app sets its own syncers/decorators, no shared fallback). Registered in UnstoppableApp.initCore().
enum UnstoppableEvmKitConfigProvider: IEvmKitConfigProvider {
    static func syncers(account _: Account, evmKit: EvmKit.Kit) -> [ITransactionSyncer]? {
        EvmKitConfigFactory.defaultSyncers(evmKit: evmKit)
    }

    static func decorators(account _: Account, evmKit: EvmKit.Kit) {
        EvmKitConfigFactory.defaultDecorators(evmKit: evmKit)
    }
}

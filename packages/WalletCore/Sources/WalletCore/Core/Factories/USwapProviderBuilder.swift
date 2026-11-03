import Foundation

/// Assembles the single `USwapMultiSwapProvider` from its per-chain builders. Everything it needs is
/// passed in, so `Core` can build it while it is still being initialised.
enum USwapProviderBuilder {
    struct Dependencies {
        let adapterManager: AdapterManager
        let evmBlockchainManager: EvmBlockchainManager
        let tronKitManager: TronKitManager
        let accountManager: AccountManager
        let solanaKitManager: SolanaKitManager
        let localStorage: LocalStorage
    }

    static func make(
        api: USwapMultiSwapApi,
        assetCatalog: USwapAssetCatalog,
        providerManager: MultiSwapProviderManager,
        dependencies: Dependencies
    ) -> USwapMultiSwapProvider {
        USwapMultiSwapProvider(
            api: api,
            assetCatalog: assetCatalog,
            commitRequestBuilder: USwapCommitRequestBuilder(),
            tracker: tracker(api: api, localStorage: dependencies.localStorage),
            rateQuoteFactory: rateQuoteFactory(dependencies: dependencies),
            finalQuoteFactory: finalQuoteFactory(dependencies: dependencies),
            providerManager: providerManager
        )
    }

    /// Nothing built here may read `Core.shared`: `make` runs inside `Core.init`, before `Core.instance` is set.
    private static func rateQuoteFactory(dependencies: Dependencies) -> USwapRateQuoteFactory {
        USwapRateQuoteFactory(
            builders: [
                USwapAllowanceRateQuoteBuilder(allowanceHelper: MultiSwapAllowanceHelper(adapterManager: dependencies.adapterManager)),
                USwapPlainRateQuoteBuilder(),
            ]
        )
    }

    private static func finalQuoteFactory(dependencies: Dependencies) -> USwapFinalQuoteFactory {
        let adapterManager = dependencies.adapterManager

        return USwapFinalQuoteFactory(
            builders: [
                USwapEvmFinalQuoteBuilder(
                    evmBlockchainManager: dependencies.evmBlockchainManager,
                    evmFeeEstimator: EvmFeeEstimator(),
                    adapterManager: adapterManager
                ),
                USwapUtxoFinalQuoteBuilder(adapterManager: adapterManager),
                USwapTronFinalQuoteBuilder(
                    tronKitManager: dependencies.tronKitManager,
                    adapterManager: adapterManager
                ),
                USwapZcashFinalQuoteBuilder(adapterManager: adapterManager),
                USwapTonFinalQuoteBuilder(accountManager: dependencies.accountManager, adapterManager: adapterManager),
                USwapStellarFinalQuoteBuilder(adapterManager: adapterManager),
                USwapMoneroFinalQuoteBuilder(adapterManager: adapterManager),
                USwapZanoFinalQuoteBuilder(adapterManager: adapterManager),
                USwapSolanaFinalQuoteBuilder(adapterManager: adapterManager, solanaKitManager: dependencies.solanaKitManager),
                USwapXrpFinalQuoteBuilder(adapterManager: adapterManager),
                USwapThorChainFinalQuoteBuilder(adapterManager: adapterManager),
                USwapNearFinalQuoteBuilder(adapterManager: adapterManager),
            ]
        )
    }

    private static func tracker(api: USwapMultiSwapApi, localStorage: LocalStorage) -> USwapTracker {
        USwapTracker(
            api: api,
            shouldSimulateFailure: {
                AppConfig.showDevTools && localStorage.simulateFailSwap == .server
            }
        )
    }
}

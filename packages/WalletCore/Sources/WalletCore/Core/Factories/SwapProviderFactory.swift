import Foundation
import HsToolKit

public protocol ISwapProviderResolver {
    static func providerInfo(id: String) -> USwapProviderInfo?
    static func provider(id: String) -> IMultiSwapProvider?
}

public extension ISwapProviderResolver {
    static func providerInfo(id _: String) -> USwapProviderInfo? {
        nil
    }
}

public class SwapProviderFactory {
    private static var resolvers: [ISwapProviderResolver.Type] = []

    public static func register(_ resolvers: [ISwapProviderResolver.Type]) {
        self.resolvers.append(contentsOf: resolvers)
    }

    public static func prepend(_ resolver: ISwapProviderResolver.Type) {
        resolvers.insert(resolver, at: 0)
    }

    public static func provider(id: String) -> IMultiSwapProvider? {
        for resolver in resolvers {
            if let provider = resolver.provider(id: id) {
                return provider
            }
        }

        return nil
    }

    public static func providerInfo(id: String) -> USwapProviderInfo? {
        for resolver in resolvers {
            if let info = resolver.providerInfo(id: id) {
                return info
            }
        }

        return nil
    }

    // The ordinary swap screen must never offer a confidential provider. Not automatic: a registered
    // entry resolves through `provider(id:)` (which tracking needs) and DefaultUSwapSubProvider.rate
    // sends an explicit `providers` list, which overrides the server-side privacy filter.
    public static func swappableProviders(ids: [String]) -> [IMultiSwapProvider] {
        ids
            .filter { providerInfo(id: $0)?.confidential != true }
            .compactMap { provider(id: $0) }
    }

    public static func providerName(id: String) -> String? {
        if let info = providerInfo(id: id) {
            return info.name
        }

        let names: [String: String] = [
            OneInchMultiSwapProvider.id: OneInchMultiSwapProvider.name,
            ThorChainMultiSwapProvider.id: ThorChainMultiSwapProvider.name,
            MayaMultiSwapProvider.id: MayaMultiSwapProvider.name,
            AllBridgeMultiSwapProvider.id: AllBridgeMultiSwapProvider.name,
            UniswapV3MultiSwapProvider.id: UniswapV3MultiSwapProvider.name,
            PancakeV3MultiSwapProvider.id: PancakeV3MultiSwapProvider.name,
            StellarSwapMultiSwapProvider.id: StellarSwapMultiSwapProvider.name,
        ]

        return names[id]
    }

    // test seam: registry is global mutable state
    static func reset() {
        resolvers = []
    }
}

public enum SwapProviderResolver: ISwapProviderResolver {
    public struct Entry {
        public let info: USwapProviderInfo
        public let makeProvider: () -> IMultiSwapProvider

        public init(info: USwapProviderInfo, makeProvider: @escaping () -> IMultiSwapProvider) {
            self.info = info
            self.makeProvider = makeProvider
        }
    }

    private static let entries: [String: Entry] = Dictionary(
        uniqueKeysWithValues: [
            defaultUSwapEntry(info: .near),
            // Registered so SwapProviderFactory.provider(id:) resolves it for tracking — without
            // this, SwapHistoryManager._sync() skips the row and a private send never leaves
            // pending. It is kept off the ordinary swap screen by the confidential filter in
            // swappableProviders(ids:) above, which MultiSwapViewModel is the only caller of.
            defaultUSwapEntry(info: .nearConfidential),
            quickExUSwapEntry(info: .quickEx),
            defaultUSwapEntry(info: .letsExchange),
            defaultUSwapEntry(info: .stealthex),
            defaultUSwapEntry(info: .swapuz),
            exolixUSwapEntry(info: .exolix),
            defaultUSwapEntry(info: .cce),
            barterUSwapEntry(info: .barter),
            defaultUSwapEntry(info: .pegasus),
            defaultUSwapEntry(info: .circle),
            jupiterUSwapEntry(info: .jupiter),
            lifiUSwapEntry(info: .lifi),
            axelarUSwapEntry(info: .axelarIts),
            defaultUSwapEntry(info: .lizex),
            defaultUSwapEntry(info: .bitania),
        ].map { entry in
            (entry.info.id, entry)
        }
    )

    // Accessible so the app can build the same USwap API instance for the private send stack
    // instead of duplicating the base URL / api key construction.
    public static func uSwapApi(networkManager: NetworkManager) -> USwapMultiSwapApi {
        guard let baseURL = URL(string: "\(AppConfig.swapApiUrl)/v2") else {
            preconditionFailure("Invalid USwap API URL: \(AppConfig.swapApiUrl)")
        }

        return USwapMultiSwapApi(
            baseURL: baseURL,
            apiKey: AppConfig.uswapApiKey,
            networkManager: networkManager
        )
    }

    private static func defaultUSwapEntry(info: USwapProviderInfo) -> Entry {
        Entry(info: info, makeProvider: { defaultUSwapProvider(info: info) })
    }

    private static func quickExUSwapEntry(info: USwapProviderInfo) -> Entry {
        Entry(info: info, makeProvider: { quickExUSwapProvider(info: info) })
    }

    private static func jupiterUSwapEntry(info: USwapProviderInfo) -> Entry {
        Entry(info: info, makeProvider: { jupiterUSwapProvider(info: info) })
    }

    private static func barterUSwapEntry(info: USwapProviderInfo) -> Entry {
        Entry(info: info, makeProvider: { barterUSwapProvider(info: info) })
    }

    private static func lifiUSwapEntry(info: USwapProviderInfo) -> Entry {
        Entry(info: info, makeProvider: { lifiUSwapProvider(info: info) })
    }

    private static func exolixUSwapEntry(info: USwapProviderInfo) -> Entry {
        Entry(info: info, makeProvider: { exolixUSwapProvider(info: info) })
    }

    private static func axelarUSwapEntry(info: USwapProviderInfo) -> Entry {
        Entry(info: info, makeProvider: { axelarUSwapProvider(info: info) })
    }

    private static func defaultUSwapProvider(info: USwapProviderInfo) -> IMultiSwapProvider {
        let api = uSwapApi(networkManager: NetworkManager(logger: nil))
        let subProvider = defaultUSwapSubProvider(info: info, api: api)

        return uSwapProvider(subProvider: subProvider)
    }

    private static func quickExUSwapProvider(info: USwapProviderInfo) -> IMultiSwapProvider {
        let api = uSwapApi(networkManager: NetworkManager(logger: nil))
        let subProvider = QuickExUSwapSubProvider(
            info: info,
            api: api,
            assetRepository: USwapAssetRepository(
                providerId: info.id,
                api: api,
                storage: Core.shared.swapAssetStorage
            ),
            commitRequestBuilder: USwapCommitRequestBuilder(providerId: info.id),
            tracker: uSwapTracker(api: api)
        )

        return uSwapProvider(subProvider: subProvider)
    }

    private static func jupiterUSwapProvider(info: USwapProviderInfo) -> IMultiSwapProvider {
        let api = uSwapApi(networkManager: NetworkManager(logger: nil))
        let subProvider = JupiterUSwapSubProvider(
            info: info,
            api: api,
            assetRepository: nil,
            commitRequestBuilder: USwapCommitRequestBuilder(providerId: info.id),
            tracker: uSwapTracker(api: api)
        )

        return uSwapProvider(subProvider: subProvider)
    }

    private static func barterUSwapProvider(info: USwapProviderInfo) -> IMultiSwapProvider {
        let api = uSwapApi(networkManager: NetworkManager(logger: nil))
        let subProvider = BarterUSwapSubProvider(
            info: info,
            api: api,
            assetRepository: nil,
            commitRequestBuilder: USwapCommitRequestBuilder(providerId: info.id),
            tracker: uSwapTracker(api: api)
        )

        return uSwapProvider(subProvider: subProvider)
    }

    private static func lifiUSwapProvider(info: USwapProviderInfo) -> IMultiSwapProvider {
        let api = uSwapApi(networkManager: NetworkManager(logger: nil))
        let subProvider = LifiUSwapSubProvider(
            info: info,
            api: api,
            assetRepository: nil,
            commitRequestBuilder: USwapCommitRequestBuilder(providerId: info.id),
            tracker: uSwapTracker(api: api)
        )

        return uSwapProvider(subProvider: subProvider)
    }

    private static func exolixUSwapProvider(info: USwapProviderInfo) -> IMultiSwapProvider {
        let api = uSwapApi(networkManager: NetworkManager(logger: nil))
        let subProvider = ExolixUSwapSubProvider(
            info: info,
            api: api,
            assetRepository: USwapAssetRepository(
                providerId: info.id,
                api: api,
                storage: Core.shared.swapAssetStorage,
                includeAsset: { identifier in
                    ExolixUSwapSubProvider.includesInAssetMap(identifier: identifier)
                }
            ),
            commitRequestBuilder: USwapCommitRequestBuilder(providerId: info.id),
            tracker: uSwapTracker(api: api),
            accountManager: Core.shared.accountManager,
            adapterManager: Core.shared.adapterManager
        )

        return uSwapProvider(subProvider: subProvider)
    }

    private static func axelarUSwapProvider(info: USwapProviderInfo) -> IMultiSwapProvider {
        let api = uSwapApi(networkManager: NetworkManager(logger: nil))
        let subProvider = DefaultUSwapSubProvider(
            info: info,
            api: api,
            assetRepository: USwapAssetRepository(
                providerId: info.id,
                api: api,
                storage: Core.shared.swapAssetStorage
            ),
            commitRequestBuilder: USwapCommitRequestBuilder(
                providerId: info.id,
                shouldIncludeSourceAddress: { token in
                    token.blockchain.type.isEvm ||
                        token.blockchainType == .tron ||
                        token.blockchainType == .ton ||
                        token.blockchainType == .solana ||
                        token.blockchainType == .stellar
                }
            ),
            tracker: uSwapTracker(api: api)
        )

        return uSwapProvider(subProvider: subProvider)
    }

    private static func stellarSwapProvider() -> IMultiSwapProvider {
        let api = uSwapApi(networkManager: NetworkManager(logger: nil))

        return StellarSwapMultiSwapProvider(
            api: api,
            tracker: uSwapTracker(api: api)
        )
    }

    private static func defaultUSwapSubProvider(info: USwapProviderInfo, api: USwapMultiSwapApi) -> DefaultUSwapSubProvider {
        DefaultUSwapSubProvider(
            info: info,
            api: api,
            assetRepository: USwapAssetRepository(
                providerId: info.id,
                api: api,
                storage: Core.shared.swapAssetStorage
            ),
            commitRequestBuilder: USwapCommitRequestBuilder(providerId: info.id),
            tracker: uSwapTracker(api: api)
        )
    }

    private static func uSwapProvider(subProvider: USwapSubProvider) -> IMultiSwapProvider {
        USwapMultiSwapProvider(
            subProvider: subProvider,
            rateQuoteFactory: uSwapRateQuoteFactory(),
            finalQuoteFactory: uSwapFinalQuoteFactory()
        )
    }

    private static func uSwapRateQuoteFactory() -> USwapRateQuoteFactory {
        USwapRateQuoteFactory(
            builders: [
                USwapAllowanceRateQuoteBuilder(allowanceHelper: MultiSwapAllowanceHelper()),
                USwapPlainRateQuoteBuilder(),
            ]
        )
    }

    private static func uSwapFinalQuoteFactory() -> USwapFinalQuoteFactory {
        let adapterManager = Core.shared.adapterManager

        return USwapFinalQuoteFactory(
            builders: [
                USwapEvmFinalQuoteBuilder(
                    evmBlockchainManager: Core.shared.evmBlockchainManager,
                    evmFeeEstimator: EvmFeeEstimator()
                ),
                USwapUtxoFinalQuoteBuilder(adapterManager: adapterManager),
                USwapTronFinalQuoteBuilder(
                    tronKitManager: Core.shared.tronAccountManager.tronKitManager
                ),
                USwapZcashFinalQuoteBuilder(adapterManager: adapterManager),
                USwapTonFinalQuoteBuilder(accountManager: Core.shared.accountManager),
                USwapStellarFinalQuoteBuilder(adapterManager: adapterManager),
                USwapMoneroFinalQuoteBuilder(adapterManager: adapterManager),
                USwapZanoFinalQuoteBuilder(adapterManager: adapterManager),
                USwapSolanaFinalQuoteBuilder(adapterManager: adapterManager),
            ]
        )
    }

    private static func uSwapTracker(api: USwapMultiSwapApi) -> USwapTracker {
        USwapTracker(
            api: api,
            shouldSimulateFailure: {
                AppConfig.showDevTools && Core.shared.localStorage.simulateFailSwap == .server
            }
        )
    }

    private static func uSwapTracker(networkManager: NetworkManager) -> USwapTracker {
        uSwapTracker(api: uSwapApi(networkManager: networkManager))
    }

    public static func providerInfo(id: String) -> USwapProviderInfo? {
        entries[id]?.info
    }

    public static func provider(id: String) -> IMultiSwapProvider? {
        if id == OneInchMultiSwapProvider.id, let apiKey = AppConfig.oneInchApiKey {
            return OneInchMultiSwapProvider(
                apiKey: apiKey,
                tracker: uSwapTracker(networkManager: Core.shared.networkManager)
            )
        }

        if id == ThorChainMultiSwapProvider.id {
            return ThorChainMultiSwapProvider(
                tracker: uSwapTracker(networkManager: Core.shared.networkManager)
            )
        }

        if id == MayaMultiSwapProvider.id {
            return MayaMultiSwapProvider(
                tracker: uSwapTracker(networkManager: Core.shared.networkManager)
            )
        }

        if id == AllBridgeMultiSwapProvider.id {
            return AllBridgeMultiSwapProvider()
        }

        if id == UniswapV3MultiSwapProvider.id,
           let provider = try? UniswapV3MultiSwapProvider(
               tracker: uSwapTracker(networkManager: Core.shared.networkManager)
           )
        {
            return provider
        }

        if id == PancakeV3MultiSwapProvider.id,
           let provider = try? PancakeV3MultiSwapProvider(
               tracker: uSwapTracker(networkManager: Core.shared.networkManager)
           )
        {
            return provider
        }

        // Stellar-native swaps are exposed as one provider. The fallback route ids stay
        // internal to StellarSwapMultiSwapProvider and intentionally do not resolve here.
        if id == StellarSwapMultiSwapProvider.id {
            return stellarSwapProvider()
        }

        if let entry = entries[id] {
            return entry.makeProvider()
        }

        return nil
    }
}

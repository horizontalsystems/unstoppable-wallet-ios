import SwiftUI
import WalletCore
import WidgetKit

@main
struct UnstoppableApp: App {
    @UIApplicationDelegateAdaptor var appDelegate: AppDelegate

    private let initResult: Result<Void, Error>

    init() {
        #if DEV
            AppEnvironment.configure(.dev)
        #endif

        Theme.updateNavigationBarTheme() // TODO: get rid of this

        do {
            try Self.initCore()

            initResult = .success(())
        } catch {
            initResult = .failure(error)
        }
    }

    var body: some Scene {
        WindowGroup {
            switch initResult {
            case .success:
                AppView()
            case let .failure(error):
                LaunchErrorView(error: error)
            }
        }
    }

    private static func initCore() throws {
        SwapProviderFactory.register([SwapProviderResolver.self])

        // .tonConnect is not registered: TonConnectEventHandler is disabled, a parsed link would
        // only die in the handler chain. Register it together with re-enabling the handler.
        [DeepLinkRoute.walletConnect, .tonTransfer, .coin, .referral, .openCryptoPay, .transfer]
            .forEach { DeepLinkRouteFactory.register($0) }
        [AppEventHandlerKind.walletConnect, .widgetCoin, .address, .telegramUser, .openCryptoPay]
            .forEach { AppEventHandlerFactory.register($0) }
        DeepLinkPresenterFactory.register(sendPresenter: DeepLinkPresenterFactory.sendPresenter)

        // Registered BEFORE Core.initApp: adapters/kits are created asynchronously on wallet events, and their
        // factories fatalError on a missing provider — registration must deterministically precede any creation.
        EvmKitConfigFactory.register(UnstoppableEvmKitConfigProvider.self)
        EvmTransactionConverterFactory.register(UnstoppableEvmTransactionConverterProvider.self)

        try Core.initApp(config: Core.Config(), widgetRefresher: WidgetRefresher())

        initPrivateSend()

        Core.shared.appManager.didFinishLaunching()
    }

    // Wired after Core.initApp because every piece reads Core.shared. Left unwired,
    // Core.privateSendService stays nil and the private send toggle is simply never shown.
    private static func initPrivateSend() {
        // One API instance for the whole private send stack, built the same way the swap providers
        // build theirs (AppConfig.swapApiUrl + AppConfig.uswapApiKey).
        let uSwapApi = SwapProviderResolver.uSwapApi(networkManager: Core.shared.networkManager)

        // The token manager's source of confidential provider ids, built as a single instance: a
        // second registry would double the GET /v2/providers traffic and could disagree about which
        // providers are confidential.
        let confidentialProviderRegistry = ConfidentialProviderRegistry(
            api: uSwapApi,
            storage: Core.shared.confidentialProviderStorage
        )

        // Required, not an optimisation: USwapAssetRepository.init calls sync(), so a non-memoised
        // factory would refetch GET /v2/tokens on every lookup. Retained by the closures handed to
        // the token manager and the service below, which Core.privateSendService keeps alive.
        let repositoryCache = USwapAssetRepositoryCache(
            api: uSwapApi,
            storage: Core.shared.swapAssetStorage
        )

        // One instance, shared into the service: it is the single source of truth for "can this token
        // be sent privately", and it shares the repository cache so the private-send token list is
        // fetched and persisted once per confidential provider.
        let privateSendTokenManager = PrivateSendTokenManager(
            registry: confidentialProviderRegistry,
            repository: repositoryCache.repository(providerId:)
        )

        Core.privateSendService = PrivateSendService(
            api: uSwapApi,
            tokenManager: privateSendTokenManager,
            assetRepository: repositoryCache.repository(providerId:),
            // sourceAddress is deliberately never sent: it is optional for transfer providers and
            // handing the provider the sender's address defeats the point of a private send.
            commitRequestBuilder: { USwapCommitRequestBuilder(providerId: $0, shouldIncludeSourceAddress: { _ in false }) }
        )

        // Shares the API and repository cache; the factory keeps the NEAR repository (and its
        // first /v2/tokens fetch) uncreated until the CrossPay screen opens.
        Core.crossPayService = CrossPayService(
            api: uSwapApi,
            assetRepository: repositoryCache.repository(providerId:),
            commitRequestBuilder: USwapCommitRequestBuilder(providerId: CrossPayService.providerId, shouldIncludeSourceAddress: { _ in false })
        )
    }
}

struct WidgetRefresher: IWidgetRefresher {
    func refreshAll() {
        AppWidgetConstants.allKinds.forEach { WidgetCenter.shared.reloadTimelines(ofKind: $0) }
    }

    func refreshWatchlist() {
        WidgetCenter.shared.reloadTimelines(ofKind: AppWidgetConstants.watchlistWidgetKind)
    }
}

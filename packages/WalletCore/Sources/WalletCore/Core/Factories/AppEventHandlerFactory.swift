import MarketKit

public class AppEventHandlerFactory {
    // Empty by default: every app registers its own set before Core.initApp.
    // Registration after Core.initApp has no effect.
    private static var kinds = Set<AppEventHandlerKind>()

    public static func register(_ kind: AppEventHandlerKind) {
        kinds.insert(kind)
    }

    static func resolved() -> Set<AppEventHandlerKind> {
        kinds
    }

    private let marketKit: MarketKit.Kit
    private let walletConnectSessionManager: WalletConnectSessionManager?
    private let walletConnectRequestHandler: WalletConnectRequestChain?
    private let cloudBackupManager: CloudBackupManager
    private let accountManager: AccountManager
    private let lockManager: LockManager

    init(
        marketKit: MarketKit.Kit,
        walletConnectSessionManager: WalletConnectSessionManager?,
        walletConnectRequestHandler: WalletConnectRequestChain?,
        cloudBackupManager: CloudBackupManager,
        accountManager: AccountManager,
        lockManager: LockManager
    ) {
        self.marketKit = marketKit
        self.walletConnectSessionManager = walletConnectSessionManager
        self.walletConnectRequestHandler = walletConnectRequestHandler
        self.cloudBackupManager = cloudBackupManager
        self.accountManager = accountManager
        self.lockManager = lockManager
    }

    // Builds handlers for the registered kinds. Chain order is fixed here and does not depend
    // on registration order: it is the fallback-resolution order of EventHandler.
    func handlers() -> [IEventHandler] {
        let kinds = Self.kinds
        var handlers = [IEventHandler]()

        if kinds.contains(.walletConnect), let walletConnectSessionManager, let walletConnectRequestHandler {
            handlers.append(WalletConnectHandlerModule.handler(
                walletConnectManager: walletConnectSessionManager,
                walletConnectRequestHandler: walletConnectRequestHandler,
                cloudAccountBackupManager: cloudBackupManager,
                accountManager: accountManager,
                lockManager: lockManager
            ))
        }
        // TonConnectEventHandler is disabled — DeepLinkRoute.tonConnect stays a known dangling route:
        // handlers.append(TonConnectEventHandler(tonConnectManager: tonConnectManager))
        if kinds.contains(.widgetCoin) {
            handlers.append(WidgetCoinEventHandler(marketKit: marketKit))
        }
        if kinds.contains(.address) {
            handlers.append(AddressEventHandler(marketKit: marketKit))
        }
        if kinds.contains(.telegramUser) {
            handlers.append(TelegramUserHandler(marketKit: marketKit))
        }
        if kinds.contains(.openCryptoPay) {
            handlers.append(OpenCryptoPayEventHandler())
        }

        return handlers
    }
}

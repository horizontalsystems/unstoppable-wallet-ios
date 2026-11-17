import Foundation
import HsToolKit

/// Builds the started kit: configures the SDK first, then wires the services over the shared registries
class WCKitFactory: IWCKitFactory {
    private let signClient: WCSignClient
    private let responder: WCResponder
    private let storage: WCSessionStorage
    private let parsers: WCParserRegistry
    private let verifiers: WCVerifierRegistry
    private let chainSupports: WCChainSupportRegistry
    private let directHandlers: WCDirectHandlerRegistry
    private let accountManager: AccountManager
    private let lockManager: LockManager
    private let appManager: AppManager
    private let securityManager: SecurityManager
    private let networkManager: NetworkManager
    private let logger: Logger

    init(signClient: WCSignClient, responder: WCResponder, storage: WCSessionStorage, parsers: WCParserRegistry, verifiers: WCVerifierRegistry, chainSupports: WCChainSupportRegistry, directHandlers: WCDirectHandlerRegistry, accountManager: AccountManager, lockManager: LockManager, appManager: AppManager, securityManager: SecurityManager, networkManager: NetworkManager, logger: Logger) {
        self.signClient = signClient
        self.responder = responder
        self.storage = storage
        self.parsers = parsers
        self.verifiers = verifiers
        self.chainSupports = chainSupports
        self.directHandlers = directHandlers
        self.accountManager = accountManager
        self.lockManager = lockManager
        self.appManager = appManager
        self.securityManager = securityManager
        self.networkManager = networkManager
        self.logger = logger
    }

    func makeKit() throws -> WCKit {
        let info = WCClientInfo(
            projectId: AppConfig.walletConnectV2ProjectKey ?? "c4f79cc821944d9680842e34466bfb",
            name: AppConfig.appName,
            description: "",
            url: AppConfig.appWebPageLink,
            icons: ["https://raw.githubusercontent.com/horizontalsystems/HS-Design/master/PressKit/UW-AppIcon-on-light.png"],
            redirectScheme: DeepLinkManager.deepLinkScheme + "://"
        )
        try WCConfigurator(sdk: WCSdkConfigurator()).configure(info: info, bundleIdentifier: Bundle.main.bundleIdentifier ?? "")

        let verifyService = WCVerifyService(
            whitelist: WCDappWhitelist(provider: WhitelistDappProvider(networkManager: networkManager)),
            scamProtectionGate: WCScamProtectionGate(securityManager: securityManager)
        )

        return WCKit(
            signClient: signClient,
            sessionService: WCSessionService(signClient: signClient, storage: storage, accountProvider: accountManager, logger: logger.scoped(with: "WC.Session")),
            requestService: WCRequestService(parsers: parsers, verifiers: verifiers, responder: responder, logger: logger.scoped(with: "WC.Request")),
            directHandlers: directHandlers,
            responder: responder,
            pairingService: WCPairingService(signClient: signClient),
            verifyService: verifyService,
            namespaceBuilder: WCNamespaceBuilder(registry: chainSupports),
            accountProvider: accountManager,
            lockProvider: lockManager,
            foregroundProvider: appManager,
            logger: logger.scoped(with: "WC.Kit")
        )
    }
}

import Foundation
import HsToolKit

// Builds the started kit: configures the SDK first, then wires the services over the shared registries
class WCNKitFactory: IWCNKitFactory {
    private let signClient: WCNSignClient
    private let responder: WCNResponder
    private let storage: WCNSessionStorage
    private let parsers: WCNParserRegistry
    private let verifiers: WCNVerifierRegistry
    private let chainSupports: WCNChainSupportRegistry
    private let directHandlers: WCNDirectHandlerRegistry
    private let accountManager: AccountManager
    private let lockManager: LockManager
    private let securityManager: SecurityManager
    private let purchaseManager: PurchaseManager
    private let networkManager: NetworkManager
    private let logger: Logger

    init(signClient: WCNSignClient, responder: WCNResponder, storage: WCNSessionStorage, parsers: WCNParserRegistry, verifiers: WCNVerifierRegistry, chainSupports: WCNChainSupportRegistry, directHandlers: WCNDirectHandlerRegistry, accountManager: AccountManager, lockManager: LockManager, securityManager: SecurityManager, purchaseManager: PurchaseManager, networkManager: NetworkManager, logger: Logger) {
        self.signClient = signClient
        self.responder = responder
        self.storage = storage
        self.parsers = parsers
        self.verifiers = verifiers
        self.chainSupports = chainSupports
        self.directHandlers = directHandlers
        self.accountManager = accountManager
        self.lockManager = lockManager
        self.securityManager = securityManager
        self.purchaseManager = purchaseManager
        self.networkManager = networkManager
        self.logger = logger
    }

    func makeKit() throws -> WCNKit {
        let info = WCNClientInfo(
            projectId: AppConfig.walletConnectV2ProjectKey ?? "c4f79cc821944d9680842e34466bfb",
            name: AppConfig.appName,
            description: "",
            url: AppConfig.appWebPageLink,
            icons: ["https://raw.githubusercontent.com/horizontalsystems/HS-Design/master/PressKit/UW-AppIcon-on-light.png"],
            redirectScheme: DeepLinkManager.deepLinkScheme + "://"
        )
        WCNLog.log("factory: configuring sdk projectId=\(info.projectId.prefix(6))… bundle=\(Bundle.main.bundleIdentifier ?? "")")
        try WCNConfigurator(sdk: WCNSdkConfigurator()).configure(info: info, bundleIdentifier: Bundle.main.bundleIdentifier ?? "")
        WCNLog.log("factory: sdk configured, building kit")

        let verifyService = WCNVerifyService(
            whitelist: WCNDappWhitelist(provider: WhitelistDappProvider(networkManager: networkManager)),
            premiumGate: WCNPremiumGate(securityManager: securityManager, purchaseManager: purchaseManager)
        )

        return WCNKit(
            signClient: signClient,
            sessionService: WCNSessionService(signClient: signClient, storage: storage, accountProvider: accountManager, logger: logger.scoped(with: "WCN.Session")),
            requestService: WCNRequestService(parsers: parsers, verifiers: verifiers, responder: responder, logger: logger.scoped(with: "WCN.Request")),
            directHandlers: directHandlers,
            responder: responder,
            pairingService: WCNPairingService(signClient: signClient),
            verifyService: verifyService,
            namespaceBuilder: WCNNamespaceBuilder(registry: chainSupports),
            accountProvider: accountManager,
            lockProvider: lockManager,
            logger: logger.scoped(with: "WCN.Kit")
        )
    }
}

import Combine
import GRDB
import HsToolKit

protocol IWCNKitFactory: AnyObject {
    func makeKit() throws -> WCNKit
}

// Root of the module: owns the registries and the lazily started kit, the relay socket opens only when needed
class WCNManager {
    let chainSupportRegistry: WCNChainSupportRegistry
    let sendHandlerRegistry: WCNSendHandlerRegistry
    let directHandlerRegistry: WCNDirectHandlerRegistry
    let signMessageHandlerRegistry: WCNSignMessageHandlerRegistry

    private let storage: WCNSessionStorage
    private let kitFactory: IWCNKitFactory
    private let logger: Logger?
    private let kitSubject = CurrentValueSubject<WCNKit?, Never>(nil)

    init(storage: WCNSessionStorage, kitFactory: IWCNKitFactory, chainSupportRegistry: WCNChainSupportRegistry, sendHandlerRegistry: WCNSendHandlerRegistry, directHandlerRegistry: WCNDirectHandlerRegistry, signMessageHandlerRegistry: WCNSignMessageHandlerRegistry, logger: Logger? = nil) {
        self.storage = storage
        self.kitFactory = kitFactory
        self.chainSupportRegistry = chainSupportRegistry
        self.sendHandlerRegistry = sendHandlerRegistry
        self.directHandlerRegistry = directHandlerRegistry
        self.signMessageHandlerRegistry = signMessageHandlerRegistry
        self.logger = logger
        WCNLog.log("manager created")
    }

    // persisted sessions mean a relay reconnect may deliver a request right away: subscribe before it happens
    func start() {
        let count = (try? storage.sessions().count) ?? 0
        WCNLog.log("manager start: stored sessions=\(count)")
        guard count > 0 else {
            return
        }
        do {
            _ = try kit()
        } catch {
            WCNLog.log("manager start: eager kit failed \(error)")
            logger?.error("eager WalletConnect start failed: \(error)")
        }
    }

    var kitPublisher: AnyPublisher<WCNKit?, Never> {
        kitSubject.eraseToAnyPublisher()
    }

    var startedKit: WCNKit? {
        kitSubject.value
    }

    var pendingRequestCount: Int {
        kitSubject.value?.pendingRequestCount ?? 0
    }

    // emits the active-account pending-request count as the kit starts and as its pending list changes
    var pendingRequestCountPublisher: AnyPublisher<Int, Never> {
        kitSubject
            .map { kit -> AnyPublisher<Int, Never> in
                guard let kit else { return Just(0).eraseToAnyPublisher() }
                return kit.pendingRequestsPublisher
                    .map { _ in kit.pendingRequestCount }
                    .prepend(kit.pendingRequestCount)
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }

    func kit() throws -> WCNKit {
        if let kit = kitSubject.value {
            WCNLog.log("manager kit: reuse")
            return kit
        }
        WCNLog.log("manager kit: creating")
        let kit = try kitFactory.makeKit()
        kit.start()
        kitSubject.send(kit)
        WCNLog.log("manager kit: started and published")
        return kit
    }
}

extension WCNManager {
    static func instance(dbPool: DatabasePool, evmBlockchainManager: EvmBlockchainManager, stellarKitManager: StellarKitManager, solanaKitManager: SolanaKitManager, accountManager: AccountManager, coinManager: CoinManager, lockManager: LockManager, appManager: AppManager, securityManager: SecurityManager, purchaseManager: PurchaseManager, networkManager: NetworkManager, logger: Logger) throws -> WCNManager {
        let logger = logger.scoped(with: "WCN")
        let storage = try WCNSessionStorage(dbPool: dbPool)
        let signClient = WCNSignClient()
        let responder = WCNResponder(signClient: signClient)

        let parsers = WCNParserRegistry()
        parsers.register(WCNEvmTransactionParser(evmBlockchainManager: evmBlockchainManager, coinManager: coinManager, accountManager: accountManager))
        parsers.register(WCNEvmSignMessageParser())
        parsers.register(WCNEvmWalletChainParser())
        parsers.register(WCNStellarTransactionParser())
        parsers.register(WCNSolanaTransactionParser(accountProvider: WCNSolanaAccountProvider(accountManager: accountManager)))
        parsers.register(WCNSolanaSignMessageParser())

        let verifiers = WCNVerifierRegistry()
        verifiers.register(WCNVerifyOriginVerifier())
        verifiers.register(WCNSessionScopeVerifier())
        verifiers.register(WCNSignerBindingVerifier())
        verifiers.register(WCNSwapNativeValueVerifier())
        verifiers.register(WCNTypedDataDomainVerifier())
        verifiers.register(WCNEvmOneInchRouterVerifier(routerProvider: WCNEvmSwapRouterProvider(evmBlockchainManager: evmBlockchainManager)))
        verifiers.register(WCNEvmEthSignVerifier())
        verifiers.register(WCNEvmPermitVerifier())
        verifiers.register(WCNSolanaSignMessageVerifier())

        let chainSupports = WCNChainSupportRegistry()
        chainSupports.register(WCNEvmChainSupport(evmBlockchainManager: evmBlockchainManager))
        chainSupports.register(WCNStellarChainSupport())
        chainSupports.register(WCNSolanaChainSupport())

        let sendHandlers = WCNSendHandlerRegistry()
        sendHandlers.register(WCNEvmSendHandlerFactory(evmBlockchainManager: evmBlockchainManager, accountManager: accountManager, responder: responder))
        sendHandlers.register(WCNStellarSendHandlerFactory(stellarKitManager: stellarKitManager, accountManager: accountManager, coinManager: coinManager, responder: responder))
        sendHandlers.register(WCNSolanaSendHandlerFactory(solanaKitManager: solanaKitManager, accountManager: accountManager, coinManager: coinManager, responder: responder))

        let directHandlers = WCNDirectHandlerRegistry()
        directHandlers.register(WCNEvmWalletChainHandler(chainResolver: WCNEvmChainResolver(evmBlockchainManager: evmBlockchainManager), responder: responder))

        let signMessageHandlers = WCNSignMessageHandlerRegistry()
        signMessageHandlers.register(WCNEvmSignMessageHandler(signerProvider: WCNEvmSignerProvider(evmBlockchainManager: evmBlockchainManager, accountManager: accountManager), responder: responder))
        signMessageHandlers.register(WCNSolanaSignMessageHandler(signerProvider: WCNSolanaSignerProvider(accountManager: accountManager), responder: responder))

        let kitFactory = WCNKitFactory(
            signClient: signClient,
            responder: responder,
            storage: storage,
            parsers: parsers,
            verifiers: verifiers,
            chainSupports: chainSupports,
            directHandlers: directHandlers,
            accountManager: accountManager,
            lockManager: lockManager,
            appManager: appManager,
            securityManager: securityManager,
            purchaseManager: purchaseManager,
            networkManager: networkManager,
            logger: logger
        )

        return WCNManager(storage: storage, kitFactory: kitFactory, chainSupportRegistry: chainSupports, sendHandlerRegistry: sendHandlers, directHandlerRegistry: directHandlers, signMessageHandlerRegistry: signMessageHandlers, logger: logger)
    }
}

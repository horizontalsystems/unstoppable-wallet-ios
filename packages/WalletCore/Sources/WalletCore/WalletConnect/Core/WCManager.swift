import Combine
import GRDB
import HsToolKit

protocol IWCKitFactory: AnyObject {
    func makeKit() throws -> WCKit
}

// Root of the module: owns the registries and the lazily started kit, the relay socket opens only when needed
class WCManager {
    let chainSupportRegistry: WCChainSupportRegistry
    let sendHandlerRegistry: WCSendHandlerRegistry
    let directHandlerRegistry: WCDirectHandlerRegistry
    let signMessageHandlerRegistry: WCSignMessageHandlerRegistry

    private let storage: WCSessionStorage
    private let kitFactory: IWCKitFactory
    private let logger: Logger?
    private let kitSubject = CurrentValueSubject<WCKit?, Never>(nil)

    init(storage: WCSessionStorage, kitFactory: IWCKitFactory, chainSupportRegistry: WCChainSupportRegistry, sendHandlerRegistry: WCSendHandlerRegistry, directHandlerRegistry: WCDirectHandlerRegistry, signMessageHandlerRegistry: WCSignMessageHandlerRegistry, logger: Logger? = nil) {
        self.storage = storage
        self.kitFactory = kitFactory
        self.chainSupportRegistry = chainSupportRegistry
        self.sendHandlerRegistry = sendHandlerRegistry
        self.directHandlerRegistry = directHandlerRegistry
        self.signMessageHandlerRegistry = signMessageHandlerRegistry
        self.logger = logger
    }

    // persisted sessions mean a relay reconnect may deliver a request right away: subscribe before it happens
    func start() {
        let count = (try? storage.sessions().count) ?? 0
        guard count > 0 else {
            return
        }
        do {
            _ = try kit()
        } catch {
            logger?.error("eager WalletConnect start failed: \(error)")
        }
    }

    var kitPublisher: AnyPublisher<WCKit?, Never> {
        kitSubject.eraseToAnyPublisher()
    }

    var startedKit: WCKit? {
        kitSubject.value
    }

    var pendingRequestCount: Int {
        kitSubject.value?.pendingRequestCount ?? 0
    }

    var sessionCount: Int {
        kitSubject.value?.sessions.count ?? 0
    }

    var sessionCountPublisher: AnyPublisher<Int, Never> {
        kitSubject
            .map { kit -> AnyPublisher<Int, Never> in
                guard let kit else { return Just(0).eraseToAnyPublisher() }
                return kit.sessionsPublisher
                    .map(\.count)
                    .prepend(kit.sessions.count)
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
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

    func kit() throws -> WCKit {
        if let kit = kitSubject.value {
            return kit
        }
        let kit = try kitFactory.makeKit()
        kit.start()
        kitSubject.send(kit)
        return kit
    }
}

extension WCManager {
    static func instance(dbPool: DatabasePool, evmBlockchainManager: EvmBlockchainManager, stellarKitManager: StellarKitManager, solanaKitManager: SolanaKitManager, accountManager: AccountManager, coinManager: CoinManager, lockManager: LockManager, appManager: AppManager, securityManager: SecurityManager, purchaseManager: PurchaseManager, networkManager: NetworkManager, logger: Logger) throws -> WCManager {
        let logger = logger.scoped(with: "WC")
        let storage = try WCSessionStorage(dbPool: dbPool)
        let signClient = WCSignClient()
        let responder = WCResponder(signClient: signClient)

        let parsers = WCParserRegistry()
        parsers.register(WCEvmTransactionParser(evmBlockchainManager: evmBlockchainManager, coinManager: coinManager, accountManager: accountManager))
        parsers.register(WCEvmSignMessageParser())
        parsers.register(WCEvmWalletChainParser())
        parsers.register(WCStellarTransactionParser())
        parsers.register(WCSolanaTransactionParser(accountProvider: WCSolanaAccountProvider(accountManager: accountManager)))
        parsers.register(WCSolanaSignMessageParser())

        let verifiers = WCVerifierRegistry()
        verifiers.register(WCVerifyOriginVerifier())
        verifiers.register(WCSessionScopeVerifier())
        verifiers.register(WCSignerBindingVerifier())
        verifiers.register(WCSwapNativeValueVerifier())
        verifiers.register(WCTypedDataDomainVerifier())
        verifiers.register(WCEvmOneInchRouterVerifier(routerProvider: WCEvmSwapRouterProvider(evmBlockchainManager: evmBlockchainManager)))
        verifiers.register(WCEvmEthSignVerifier())
        verifiers.register(WCEvmPermitVerifier())
        verifiers.register(WCSolanaSignMessageVerifier())

        let chainSupports = WCChainSupportRegistry()
        chainSupports.register(WCEvmChainSupport(evmBlockchainManager: evmBlockchainManager))
        chainSupports.register(WCStellarChainSupport())
        chainSupports.register(WCSolanaChainSupport())

        let sendHandlers = WCSendHandlerRegistry()
        sendHandlers.register(WCEvmSendHandlerFactory(evmBlockchainManager: evmBlockchainManager, accountManager: accountManager, responder: responder))
        sendHandlers.register(WCStellarSendHandlerFactory(stellarKitManager: stellarKitManager, accountManager: accountManager, coinManager: coinManager, responder: responder))
        sendHandlers.register(WCSolanaSendHandlerFactory(solanaKitManager: solanaKitManager, accountManager: accountManager, coinManager: coinManager, responder: responder))

        let directHandlers = WCDirectHandlerRegistry()
        directHandlers.register(WCEvmWalletChainHandler(chainResolver: WCEvmChainResolver(evmBlockchainManager: evmBlockchainManager), responder: responder))

        let signMessageHandlers = WCSignMessageHandlerRegistry()
        signMessageHandlers.register(WCEvmSignMessageHandler(signerProvider: WCEvmSignerProvider(evmBlockchainManager: evmBlockchainManager, accountManager: accountManager), responder: responder))
        signMessageHandlers.register(WCSolanaSignMessageHandler(signerProvider: WCSolanaSignerProvider(accountManager: accountManager), responder: responder))

        let kitFactory = WCKitFactory(
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

        return WCManager(storage: storage, kitFactory: kitFactory, chainSupportRegistry: chainSupports, sendHandlerRegistry: sendHandlers, directHandlerRegistry: directHandlers, signMessageHandlerRegistry: signMessageHandlers, logger: logger)
    }
}

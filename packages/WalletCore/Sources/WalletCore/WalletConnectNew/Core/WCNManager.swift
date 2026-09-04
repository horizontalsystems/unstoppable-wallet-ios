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
    }

    // persisted sessions mean a relay reconnect may deliver a request right away: subscribe before it happens
    func start() {
        guard let count = try? storage.sessions().count, count > 0 else {
            return
        }
        do {
            _ = try kit()
        } catch {
            logger?.error("eager WalletConnect start failed: \(error)")
        }
    }

    var kitPublisher: AnyPublisher<WCNKit?, Never> {
        kitSubject.eraseToAnyPublisher()
    }

    var startedKit: WCNKit? {
        kitSubject.value
    }

    func kit() throws -> WCNKit {
        if let kit = kitSubject.value {
            return kit
        }
        let kit = try kitFactory.makeKit()
        kit.start()
        kitSubject.send(kit)
        return kit
    }
}

extension WCNManager {
    static func instance(dbPool: DatabasePool, evmBlockchainManager: EvmBlockchainManager, stellarKitManager: StellarKitManager, solanaKitManager: SolanaKitManager, accountManager: AccountManager, coinManager: CoinManager, lockManager: LockManager, securityManager: SecurityManager, purchaseManager: PurchaseManager, networkManager: NetworkManager, logger: Logger) throws -> WCNManager {
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
            accountManager: accountManager,
            lockManager: lockManager,
            securityManager: securityManager,
            purchaseManager: purchaseManager,
            networkManager: networkManager,
            logger: logger
        )

        return WCNManager(storage: storage, kitFactory: kitFactory, chainSupportRegistry: chainSupports, sendHandlerRegistry: sendHandlers, directHandlerRegistry: directHandlers, signMessageHandlerRegistry: signMessageHandlers, logger: logger)
    }
}

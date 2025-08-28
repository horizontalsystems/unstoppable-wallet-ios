import Foundation
import UIKit
import WalletConnectSign

protocol IWalletConnectRequestHandler {
    var namespace: String { get }
    var supportedMethods: [String] { get }
    func handle(session: Session, request: Request) -> WalletConnectRequestChain.RequestResult
    func name(by method: String) -> String?
}

protocol IWalletConnectRequestViewFactory {
    func viewController(request: WalletConnectRequest) -> WalletConnectRequestChain.ViewFactoryResult
}

class WalletConnectRequestChain {
    private var handlers = [IWalletConnectRequestHandler]()

    func append(handler: IWalletConnectRequestHandler) {
        handlers.append(handler)
    }

    func supportedMethodsBy(namespace: String) -> [String] {
        handlers.filter { handler in
            handler.namespace == namespace
        }.reduce(into: []) {
            $0.append(contentsOf: $1.supportedMethods)
        }
    }
}

extension WalletConnectRequestChain: IWalletConnectRequestHandler {
    var namespace: String { "" }

    func handle(session: Session, request: Request) -> WalletConnectRequestChain.RequestResult {
        var lastError: Error?
        for handler in handlers {
            let result = handler.handle(session: session, request: request)
            if result.successful {
                return result
            } else {
                lastError = result.error
            }
        }

        return .unsuccessful(error: lastError)
    }

    func name(by method: String) -> String? {
        for handler in handlers {
            if let name = handler.name(by: method) {
                return name
            }
        }
        return nil
    }

    var supportedMethods: [String] { handlers.reduce(into: []) { $0.append(contentsOf: $1.supportedMethods) } }
}

extension WalletConnectRequestChain: IWalletConnectRequestViewFactory {
    func viewController(request: WalletConnectRequest) -> WalletConnectRequestChain.ViewFactoryResult {
        for handler in handlers {
            guard let handler = handler as? IWalletConnectRequestViewFactory else {
                continue
            }
            let result = handler.viewController(request: request)
            switch result {
            case .unsuccessful: continue
            case .controller: return result
            }
        }

        return .unsuccessful(error: ViewFactoryError.cantRecognizeHandler)
    }
}

extension WalletConnectRequestChain {
    enum RequestResult {
        case unsuccessful(error: Error?)
        case handled
        case request(WalletConnectRequest)

        var successful: Bool {
            switch self {
            case .unsuccessful: return false
            case .handled, .request: return true
            }
        }

        var error: Error? {
            switch self {
            case let .unsuccessful(error): return error
            case .handled, .request: return nil
            }
        }
    }

    enum ViewFactoryResult {
        case unsuccessful(error: Error?)
        case controller(UIViewController?)
    }

    enum ViewFactoryError: Error {
        case cantRecognizeHandler
    }
}

extension WalletConnectRequestChain {
    static func instance(evmBlockchainManager: EvmBlockchainManager, stellarKitManager: StellarKitManager, accountManager: AccountManager) -> WalletConnectRequestChain {
        let chain = WalletConnectRequestChain()
        let factory = Eip155RequestFactory(
            evmBlockchainManager: evmBlockchainManager,
            accountManager: accountManager
        )

        let signHandler = WCSignMessageHandler<WCSignPayload>(requestFactory: factory)
        let personalSignHandler = WCSignMessageHandler<WCPersonalSignPayload>(requestFactory: factory)
        let signTypedDataHandler = WCSignMessageHandler<WCSignTypedDataPayload>(requestFactory: factory)
        let signTypedDataV4Handler = WCSignMessageHandler<WCSignTypedDataV4Payload>(requestFactory: factory)

        let sendEthereumHandler = WCEthereumTransactionHandler<WCSendEthereumTransactionPayload>(requestFactory: factory)
        let signEthereumHandler = WCEthereumTransactionHandler<WCSignEthereumTransactionPayload>(requestFactory: factory)

        let addChainHandler = WCWalletHandler<WCWalletAddChainPayload>(requestFactory: factory)
        let switchChainHandler = WCWalletHandler<WCSwitchChainPayload>(requestFactory: factory)

        chain.append(handler: signHandler)
        chain.append(handler: personalSignHandler)
        chain.append(handler: signTypedDataHandler)
        chain.append(handler: signTypedDataV4Handler)
        chain.append(handler: sendEthereumHandler)
        chain.append(handler: signEthereumHandler)
        chain.append(handler: addChainHandler)
        chain.append(handler: switchChainHandler)

        let stellarFactory = StellarRequestFactory(
            stellarKitManager: stellarKitManager,
            accountManager: accountManager
        )

        let sendStellarHandler = WCStellarTransactionHandler<WCSendStellarTransactionPayload>(requestFactory: stellarFactory)
        let signStellarHandler = WCStellarSignHandler<WCStellarSignPayload>(requestFactory: stellarFactory)

        chain.append(handler: sendStellarHandler)
        chain.append(handler: signStellarHandler)

        return chain
    }
}

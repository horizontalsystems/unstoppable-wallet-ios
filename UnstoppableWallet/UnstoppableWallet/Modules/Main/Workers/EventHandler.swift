import Combine
import Foundation
import MarketKit
import SwiftUI
import WalletConnectSign

protocol IEventHandler {
    var signal: AnyPublisher<EventHandlerSignal, Never> { get }
    func handle(source: StatPage, event: Any, eventType: EventHandler.EventType) async throws
}

enum EventHandlerSignal {
    case coinPage(Coin)
    case sendPage(EventHandler.SendParams)
    case tonConnect(EventHandler.TonConnectParams)
    case walletConnectHandleUrl(String)

    case walletConnectProposal(WalletConnectSign.Session.Proposal)
    case walletConnectRequest(WalletConnectRequest)
    case tonConnectRequest(TonConnectSendTransactionRequest)
    case tonConnectRequestFailed(TonConnectSendTransactionRequestError)

    case handled
    case fail(Error)
}

extension IEventHandler {
    var signal: AnyPublisher<EventHandlerSignal, Never> {
        Empty<EventHandlerSignal, Never>().eraseToAnyPublisher()
    }
}

class EventHandler {
    private var cancellables = Set<AnyCancellable>()
    private let deepLinkManager: DeepLinkManager
    private let signalSubject = PassthroughSubject<EventHandlerSignal, Never>()

    private var eventHandlers = [IEventHandler]()

    init(deepLinkManager: DeepLinkManager) {
        self.deepLinkManager = deepLinkManager

        deepLinkManager.newSchemePublisher
            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self] deepLink in
                self?.handle(deepLink)
            }
            .store(in: &cancellables)
    }

    private func subscribeToHandler(_ handler: IEventHandler) {
        handler.signal
            .sink { [weak self] signal in
                self?.signalSubject.send(signal)
            }
            .store(in: &cancellables)
    }

    private func handle(_ deepLink: DeepLinkManager.DeepLink?) {
        guard let deepLink else {
            return
        }

        Task { [weak self] in
            do {
                try await self?.handle(source: .main, event: deepLink, eventType: .deepLink)
            } catch {
                print("Handle error: \(error.smartDescription)")
                self?.signalSubject.send(.fail(error))
            }
        }
    }

    func append(handler: IEventHandler) {
        eventHandlers.append(handler)
        subscribeToHandler(handler)
    }

    func prepend(handler: IEventHandler) {
        if eventHandlers.count > 0 {
            eventHandlers.insert(handler, at: 0)
        } else {
            eventHandlers.append(handler)
        }
        subscribeToHandler(handler)
    }
}

extension EventHandler: IEventHandler {
    var signal: AnyPublisher<EventHandlerSignal, Never> {
        signalSubject.eraseToAnyPublisher()
    }

    func handle(source: StatPage, event: Any, eventType: EventHandler.EventType = .all) async throws {
        var lastError: Error?
        for handler in eventHandlers {
            do {
                try await handler.handle(source: source, event: event, eventType: eventType)
                return
            } catch {
                lastError = error
            }
        }

        signalSubject.send(lastError.map { EventHandlerSignal.fail($0) } ?? .handled)
    }
}

extension EventHandler {
    struct EventType: OptionSet {
        let rawValue: UInt8
        static let all: EventType = [.deepLink, .walletConnectUri, .address]

        static let deepLink = EventType(rawValue: 1 << 0)
        static let walletConnectUri = EventType(rawValue: 1 << 1)
        static let address = EventType(rawValue: 1 << 2)
    }

    enum HandleError: Error {
        case noSuitableHandler
    }
}

extension EventHandler.HandleError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noSuitableHandler: return "alert.cant_recognize".localized
        }
    }
}

extension EventHandler {
    struct SendParams: Identifiable {
        let id = UUID()

        let allowedBlockchainTypes: [BlockchainType]?
        let allowedTokenTypes: [TokenType]?
        let address: String?
        let amount: Decimal?
    }

    struct TonConnectParams: Identifiable {
        let config: TonConnectConfig
        let returnDeepLink: String?

        var id: String {
            [config.id, returnDeepLink].compactMap { $0 }.joined()
        }
    }
}

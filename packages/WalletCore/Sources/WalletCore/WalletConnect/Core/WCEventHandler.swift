import Combine
import Foundation
import ReownWalletKit

class WCEventHandler {
    private let manager: WCManager
    private var cancellables = Set<AnyCancellable>()
    private var kitCancellables = Set<AnyCancellable>()
    private let signalSubject = PassthroughSubject<EventHandlerSignal, Never>()

    init(manager: WCManager) {
        self.manager = manager
        WCLog.log("event handler created")

        manager.kitPublisher
            .compactMap { $0 }
            .sink { [weak self] in self?.subscribe(kit: $0) }
            .store(in: &cancellables)
    }

    private func subscribe(kit: WCKit) {
        WCLog.log("event handler: subscribed to kit")
        kitCancellables.removeAll()

        kit.proposalPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                WCLog.log("event handler: proposal signal \($0.proposal.id)")
                self?.signalSubject.send(.walletConnectProposal($0))
            }
            .store(in: &kitCancellables)
        kit.requestPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                WCLog.log("event handler: request signal \($0.requestId.string)")
                self?.signalSubject.send(.walletConnectRequest($0))
            }
            .store(in: &kitCancellables)
    }
}

extension WCEventHandler: IEventHandler {
    var signal: AnyPublisher<EventHandlerSignal, Never> {
        signalSubject.eraseToAnyPublisher()
    }

    func handle(source _: StatPage, event: Any, eventType _: EventHandler.EventType) async throws {
        let uri: String?
        switch event {
        case let event as String: uri = event
        case let .walletConnect(url) as DeepLinkManager.DeepLink: uri = url
        default: uri = nil
        }

        WCLog.log("event handler: handle event=\(type(of: event)) uri=\(uri.map { String($0.prefix(40)) } ?? "nil")")
        guard let uri else {
            throw EventHandler.HandleError.noSuitableHandler
        }

        // an expired link is still ours: the pairing service reports it to the user
        do {
            _ = try WalletConnectURI(uriString: uri)
        } catch WalletConnectURI.Errors.expired {
        } catch {
            throw EventHandler.HandleError.noSuitableHandler
        }

        WCLog.log("event handler: pair signal")
        signalSubject.send(.walletConnectPair(uri))
    }
}

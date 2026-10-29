import Combine
import Foundation

class TonConnectEventHandler {
    private let tonConnectManager: TonConnectManager
    private var cancellables = Set<AnyCancellable>()
    private var signalSubject = PassthroughSubject<EventHandlerSignal, Never>()

    init(tonConnectManager: TonConnectManager) {
        self.tonConnectManager = tonConnectManager

        tonConnectManager.sendTransactionRequestPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.signalSubject.send(.tonConnectRequest($0)) }
            .store(in: &cancellables)

        tonConnectManager.sendTransactionRequestErrorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.signalSubject.send(.tonConnectRequestFailed($0)) }
            .store(in: &cancellables)
    }
}

extension TonConnectEventHandler: IEventHandler {
    var signal: AnyPublisher<EventHandlerSignal, Never> {
        signalSubject.eraseToAnyPublisher()
    }

    func handle(source _: StatPage, event: Any, eventType _: EventHandler.EventType) async throws {
        var config: TonConnectConfig?
        let returnDeepLink: String?

        if case let .tonConnect(parameters) = event as? DeepLinkManager.DeepLink {
            config = try await tonConnectManager.loadTonConnectConfiguration(parameters: parameters)
            returnDeepLink = parameters.returnDeepLink
        } else if let deeplink = event as? String {
            config = try await tonConnectManager.loadTonConnectConfiguration(deeplink: deeplink)
            returnDeepLink = nil
        } else {
            returnDeepLink = nil
        }

        guard let config else {
            throw EventHandler.HandleError.noSuitableHandler
        }

        signalSubject.send(.tonConnect(EventHandler.TonConnectParams(config: config, returnDeepLink: returnDeepLink)))
    }
}

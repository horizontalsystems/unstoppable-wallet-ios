import Combine

import UIKit
import WalletConnectSign

class WalletConnectEventHandler {
    private let timeOut = 5

    private let viewModel: WalletConnectEventHandlerModel

    private var cancellables = Set<AnyCancellable>()
    private var signalSubject = PassthroughSubject<EventHandlerSignal, Never>()

    init(viewModel: WalletConnectEventHandlerModel) {
        self.viewModel = viewModel

        viewModel.showSessionRequestPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handle(request: $0) }
            .store(in: &cancellables)

        viewModel.openWalletConnectPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.openWalletConnect(mode: $0) }
            .store(in: &cancellables)
    }

    private func openWalletConnect(mode: WalletConnectEventHandlerModel.WalletConnectOpenMode) {
        switch mode {
        case let .proposal(proposal):
            signalSubject.send(.walletConnectProposal(proposal))
        }
    }

    private func handle(request: WalletConnectRequest) {
        stat(page: .main, event: .open(page: .walletConnectRequest))
        signalSubject.send(.walletConnectRequest(request))
    }
}

extension WalletConnectEventHandler: IEventHandler {
    var eventType: EventHandler.EventType { [.deepLink, .walletConnectUri] }

    var signal: AnyPublisher<EventHandlerSignal, Never> {
        signalSubject.eraseToAnyPublisher()
    }

    func handle(source _: StatPage, event: Any, eventType _: EventHandler.EventType) async throws {
        var uri: String?

        switch event {
        case let event as String:
            uri = event
        case let event as DeepLinkManager.DeepLink:
            if case let .walletConnect(url) = event {
                uri = url
            }
        default: ()
        }

        guard let uri else {
            throw EventHandler.HandleError.noSuitableHandler
        }

        do {
            try viewModel.validate(uri: uri)
        } catch {
            throw EventHandler.HandleError.noSuitableHandler
        }

//        stat(page: source, event: .walletConnectPair)
        signalSubject.send(.walletConnectHandleUrl(uri))
    }
}

import Combine
import UIKit
import WalletConnectSign

class WalletConnectEventHandlerModel {
    private var cancellables = Set<AnyCancellable>()
    private let service: WalletConnectEventHandlerService

    private let showSessionRequestSubject = PassthroughSubject<WalletConnectRequest, Never>()
    private let openWalletConnectSubject = PassthroughSubject<WalletConnectOpenMode, Never>()

    init(service: WalletConnectEventHandlerService) {
        self.service = service

        service.showSessionProposalPublisher
            .sink { [weak self] in self?.showSession(proposal: $0) }
            .store(in: &cancellables)
        service.showSessionRequestPublisher
            .sink { [weak self] in self?.showSession(request: $0) }
            .store(in: &cancellables)
    }

    private func showSession(proposal: WalletConnectSign.Session.Proposal) {
        openWalletConnectSubject.send(.proposal(proposal))
    }

    private func showSession(request: WalletConnectRequest) {
        showSessionRequestSubject.send(request)
    }

    func validate(uri: String) throws {
        try service.validate(uri: uri)
    }
}

extension WalletConnectEventHandlerModel {
    var openWalletConnectPublisher: AnyPublisher<WalletConnectOpenMode, Never> {
        openWalletConnectSubject.eraseToAnyPublisher()
    }

    var showSessionRequestPublisher: AnyPublisher<WalletConnectRequest, Never> {
        showSessionRequestSubject.eraseToAnyPublisher()
    }
}

extension WalletConnectEventHandlerModel {
    enum WalletConnectOpenMode {
        case proposal(WalletConnectSign.Session.Proposal)
    }
}

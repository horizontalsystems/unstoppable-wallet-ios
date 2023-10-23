import Combine
import UIKit
import WalletConnectSign

class WalletConnectAppShowViewModel {
    private var cancellables = Set<AnyCancellable>()
    private let service: WalletConnectAppShowService

    private let showSessionRequestSubject = PassthroughSubject<WalletConnectRequest, Never>()
    private let openWalletConnectSubject = PassthroughSubject<WalletConnectOpenMode, Never>()

    init(service: WalletConnectAppShowService) {
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

    func handleWalletConnect(url: String) throws {
        var error: WalletConnectAppShowView.WalletConnectOpenError?
        if service.activeAccount == nil {
            error = WalletConnectAppShowView.WalletConnectOpenError.noAccount
        }

        if let activeAccount = service.activeAccount, !activeAccount.type.supportsWalletConnect {
            error = WalletConnectAppShowView.WalletConnectOpenError.nonSupportedAccountType(accountTypeDescription: activeAccount.type.description)
        }

        if let activeAccount = service.activeAccount, !service.activeAccountBackedUp {
            error = WalletConnectAppShowView.WalletConnectOpenError.unbackupedAccount(account: activeAccount)
            openWalletConnectSubject.send(service.activeAccountBackedUp ? .pair(url: url) : .errorDialog(error: .unbackupedAccount(account: activeAccount)))
        }
        if let error {
            openWalletConnectSubject.send(.errorDialog(error: error))
            throw error
        }

        openWalletConnectSubject.send(.pair(url: url))
    }
}

extension WalletConnectAppShowViewModel {
    var openWalletConnectPublisher: AnyPublisher<WalletConnectOpenMode, Never> {
        openWalletConnectSubject.eraseToAnyPublisher()
    }

    var showSessionRequestPublisher: AnyPublisher<WalletConnectRequest, Never> {
        showSessionRequestSubject.eraseToAnyPublisher()
    }
}

extension WalletConnectAppShowViewModel {
    enum WalletConnectOpenMode {
        case pair(url: String)
        case proposal(WalletConnectSign.Session.Proposal)
        case errorDialog(error: WalletConnectAppShowView.WalletConnectOpenError)
    }
}

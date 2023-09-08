import Combine
import Foundation
import PinKit
import RxSwift
import WalletConnectSign

class WalletConnectAppShowService {
    private var disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()
    private let walletConnectManager: WalletConnectSessionManager
    private let cloudAccountBackupManager: CloudAccountBackupManager
    private let accountManager: AccountManager
    private let pinKit: PinKit.Kit

    private let showSessionProposalSubject = PassthroughSubject<WalletConnectSign.Session.Proposal, Never>()
    private let showSessionRequestSubject = PassthroughSubject<WalletConnectRequest, Never>()

    init(walletConnectManager: WalletConnectSessionManager, cloudAccountBackupManager: CloudAccountBackupManager, accountManager: AccountManager, pinKit: PinKit.Kit) {
        self.walletConnectManager = walletConnectManager
        self.cloudAccountBackupManager = cloudAccountBackupManager
        self.accountManager = accountManager
        self.pinKit = pinKit

        subscribe(disposeBag, walletConnectManager.service.receiveProposalObservable) { [weak self] in self?.receive(proposal: $0) }
        subscribe(disposeBag, walletConnectManager.sessionRequestReceivedObservable) { [weak self] in self?.receive(request: $0) }
    }

    private func receive(proposal: WalletConnectSign.Session.Proposal) {
        showSessionProposalSubject.send(proposal)
    }

    private func receive(request: WalletConnectRequest) {
        if !pinKit.isLocked {
            showSessionRequestSubject.send(request)
        }
    }
}

extension WalletConnectAppShowService {
    var activeAccount: Account? {
        accountManager.activeAccount
    }

    var activeAccountBackedUp: Bool {
        guard let account = accountManager.activeAccount else {
            return false
        }

        return account.backedUp || cloudAccountBackupManager.backedUp(uniqueId: account.type.uniqueId())
    }

    var showSessionProposalPublisher: AnyPublisher<WalletConnectSign.Session.Proposal, Never> {
        showSessionProposalSubject.eraseToAnyPublisher()
    }

    var showSessionRequestPublisher: AnyPublisher<WalletConnectRequest, Never> {
        showSessionRequestSubject.eraseToAnyPublisher()
    }

    func validate(uri: String) throws {
        try walletConnectManager.validate(uri: uri)
    }
}

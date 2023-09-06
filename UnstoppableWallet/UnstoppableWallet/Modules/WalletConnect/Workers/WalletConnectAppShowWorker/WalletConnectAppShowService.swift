import RxSwift
import RxCocoa
import WalletConnectSign
import PinKit

class WalletConnectAppShowService {
    private let disposeBag = DisposeBag()
    private let walletConnectManager: WalletConnectSessionManager
    private let cloudAccountBackupManager: CloudAccountBackupManager
    private let accountManager: AccountManager
    private let pinKit: PinKit.Kit

    private let showSessionProposalRelay = PublishRelay<WalletConnectSign.Session.Proposal>()
    private let showSessionRequestRelay = PublishRelay<WalletConnectRequest>()

    init(walletConnectManager: WalletConnectSessionManager, cloudAccountBackupManager: CloudAccountBackupManager, accountManager: AccountManager, pinKit: PinKit.Kit) {
        self.walletConnectManager = walletConnectManager
        self.cloudAccountBackupManager = cloudAccountBackupManager
        self.accountManager = accountManager
        self.pinKit = pinKit

        subscribe(disposeBag, walletConnectManager.service.receiveProposalObservable) { [weak self] in self?.receive(proposal: $0) }
        subscribe(disposeBag, walletConnectManager.sessionRequestReceivedObservable) { [weak self] in self?.receive(request: $0) }
    }

    private func receive(proposal: WalletConnectSign.Session.Proposal) {
            showSessionProposalRelay.accept(proposal)
    }

    private func receive(request: WalletConnectRequest) {
        if !pinKit.isLocked {
            showSessionRequestRelay.accept(request)
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

    var showSessionProposalObservable: Observable<WalletConnectSign.Session.Proposal> {
        showSessionProposalRelay.asObservable()
    }

    var showSessionRequestObservable: Observable<WalletConnectRequest> {
        showSessionRequestRelay.asObservable()
    }

}

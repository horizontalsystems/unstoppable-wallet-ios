import RxSwift
import RxCocoa
import WalletConnectSign

class WalletConnectV2AppShowService {
    private let disposeBag = DisposeBag()
    private let walletConnectV2Manager: WalletConnectV2SessionManager
    private let accountManager: AccountManager

    private let showSessionProposalRelay = PublishRelay<WalletConnectSign.Session.Proposal>()

    init(walletConnectV2Manager: WalletConnectV2SessionManager, accountManager: AccountManager) {
        self.walletConnectV2Manager = walletConnectV2Manager
        self.accountManager = accountManager

        subscribe(disposeBag, walletConnectV2Manager.service.receivePairingProposalObservable) { [weak self] in self?.receive(proposal: $0) }
    }

    private func receive(proposal: WalletConnectSign.Session.Proposal) {
        showSessionProposalRelay.accept(proposal)
    }

}

extension WalletConnectV2AppShowService {

    var activeAccount: Account? {
        accountManager.activeAccount
    }

    var showSessionProposalObservable: Observable<WalletConnectSign.Session.Proposal> {
        showSessionProposalRelay.asObservable()
    }

    var showSessionRequestObservable: Observable<WalletConnectRequest> {
        walletConnectV2Manager.sessionRequestReceivedObservable
    }

}

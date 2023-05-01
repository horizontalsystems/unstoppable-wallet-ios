import RxSwift
import RxCocoa
import WalletConnectSign
import PinKit

class WalletConnectV2AppShowService {
    private let disposeBag = DisposeBag()
    private let walletConnectV2Manager: WalletConnectV2SessionManager
    private let accountManager: AccountManager
    private let pinKit: PinKit.Kit

    private let showSessionProposalRelay = PublishRelay<WalletConnectSign.Session.Proposal>()
    private let showSessionRequestRelay = PublishRelay<WalletConnectRequest>()

    init(walletConnectV2Manager: WalletConnectV2SessionManager, accountManager: AccountManager, pinKit: PinKit.Kit) {
        self.walletConnectV2Manager = walletConnectV2Manager
        self.accountManager = accountManager
        self.pinKit = pinKit

        subscribe(disposeBag, walletConnectV2Manager.service.receiveProposalObservable) { [weak self] in self?.receive(proposal: $0) }
        subscribe(disposeBag, walletConnectV2Manager.sessionRequestReceivedObservable) { [weak self] in self?.receive(request: $0) }
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

extension WalletConnectV2AppShowService {

    var activeAccount: Account? {
        accountManager.activeAccount
    }

    var showSessionProposalObservable: Observable<WalletConnectSign.Session.Proposal> {
        showSessionProposalRelay.asObservable()
    }

    var showSessionRequestObservable: Observable<WalletConnectRequest> {
        showSessionRequestRelay.asObservable()
    }

}

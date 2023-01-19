import UIKit
import RxSwift
import RxCocoa
import WalletConnectSign

class WalletConnectV2AppShowViewModel {
    private let disposeBag = DisposeBag()
    private let service: WalletConnectV2AppShowService

    private let showSessionRequestRelay = PublishRelay<WalletConnectRequest>()
    private let openWalletConnectRelay = PublishRelay<WalletConnectOpenMode>()

    init(service: WalletConnectV2AppShowService) {
        self.service = service

        subscribe(disposeBag, service.showSessionProposalObservable) { [weak self] in self?.showSession(proposal: $0) }
        subscribe(disposeBag, service.showSessionRequestObservable) { [weak self] in self?.showSession(request: $0) }
    }

    private func showSession(proposal: WalletConnectSign.Session.Proposal) {
        openWalletConnectRelay.accept(.proposal(proposal))
    }

    private func showSession(request: WalletConnectRequest) {
        showSessionRequestRelay.accept(request)
    }

    func onWalletConnectDeepLink(url: String) {
        guard let activeAccount = service.activeAccount else {
            openWalletConnectRelay.accept(.errorDialog(error: .noAccount))
            return
        }

        if !activeAccount.type.supportsWalletConnect {
            openWalletConnectRelay.accept(.errorDialog(error: .nonSupportedAccountType(accountTypeDescription: activeAccount.type.description)))
            return
        }

        openWalletConnectRelay.accept(activeAccount.backedUp ? .pair(url: url) : .errorDialog(error: .unbackupedAccount))
    }

}

extension WalletConnectV2AppShowViewModel {

    var openWalletConnectSignal: Signal<WalletConnectOpenMode> {
        openWalletConnectRelay.asSignal()
    }

    var showSessionRequestSignal: Signal<WalletConnectRequest> {
        showSessionRequestRelay.asSignal()
    }

}


extension WalletConnectV2AppShowViewModel {

    enum WalletConnectOpenMode {
        case pair(url: String)
        case proposal(WalletConnectSign.Session.Proposal)
        case errorDialog(error: WalletConnectV2AppShowView.WalletConnectOpenError)
    }

}

import Foundation

class RestoreWalletPresenter {

    let delegate: RestoreWalletPresenterDelegate
    let router: RestoreWalletRouterProtocol
    weak var view: RestoreWalletViewProtocol?

    init(delegate: RestoreWalletPresenterDelegate, router: RestoreWalletRouterProtocol) {
        self.delegate = delegate
        self.router = router
    }

}

extension RestoreWalletPresenter: RestoreWalletViewDelegate {

    func cancelDidTap() {
        router.close()
    }

}

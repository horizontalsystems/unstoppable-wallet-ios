import Foundation

class WalletPresenter {

    private let router: WalletRouterProtocol

    init(router: WalletRouterProtocol) {
        self.router = router
    }

}

extension WalletPresenter: WalletViewDelegate {

}

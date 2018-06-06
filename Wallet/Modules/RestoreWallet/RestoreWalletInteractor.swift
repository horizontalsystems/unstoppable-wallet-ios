import Foundation

class RestoreWalletInteractor: RestoreWalletViewDelegate {

    let router: RestoreWalletRouterProtocol
    let presenter: RestoreWalletPresenterProtocol

    init(router: RestoreWalletRouterProtocol, presenter: RestoreWalletPresenterProtocol) {
        self.router = router
        self.presenter = presenter
    }

    func cancelDidTap() {
        router.close()
    }

}

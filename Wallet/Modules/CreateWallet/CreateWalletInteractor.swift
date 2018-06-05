import Foundation

class CreateWalletInteractor: CreateWalletViewDelegate {

    let router: CreateWalletRouterProtocol
    let presenter: CreateWalletPresenterProtocol
    let dataProvider: CreateWalletDataProviderProtocol

    init(router: CreateWalletRouterProtocol, presenter: CreateWalletPresenterProtocol, dataProvider: CreateWalletDataProviderProtocol) {
        self.router = router
        self.presenter = presenter
        self.dataProvider = dataProvider
    }

    func viewDidLoad() {
        guard let words = dataProvider.generateWords() else {
            presenter.showError()
            return
        }

        presenter.show(words: words)
    }

    func cancelDidTap() {
        router.close()
    }

}

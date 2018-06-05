import Foundation

class CreateWalletInteractor: CreateWalletViewDelegate {

    let presenter: CreateWalletPresenterProtocol
    let dataProvider: CreateWalletDataProviderProtocol

    init(presenter: CreateWalletPresenterProtocol, dataProvider: CreateWalletDataProviderProtocol) {
        self.presenter = presenter
        self.dataProvider = dataProvider
    }

    func viewDidLoad() {
        guard let words = dataProvider.generateWords() else {
            return
        }

        presenter.show(words: words)
    }

}

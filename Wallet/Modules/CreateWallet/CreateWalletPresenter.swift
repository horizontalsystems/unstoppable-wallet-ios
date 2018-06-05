import Foundation

class CreateWalletPresenter: CreateWalletPresenterProtocol {

    weak var view: CreateWalletViewProtocol?

    func show(words: [String]) {
        view?.show(words: words)
    }

    func showError() {

    }

}

import Foundation

class CreateWalletPresenter: CreateWalletPresenterProtocol {

    weak var view: CreateWalletViewProtocol?

    func show(words: [String]) {
        view?.show(wordsString: words.joined(separator: " "))
    }

}

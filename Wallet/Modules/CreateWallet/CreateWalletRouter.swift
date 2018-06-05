import Foundation
import BitcoinKit

class CreateWalletRouter {

    static var viewController: UIViewController {
        let presenter = CreateWalletPresenter()
        let interactor = CreateWalletInteractor(presenter: presenter, dataProvider: CreateWalletDataProvider())
        let viewController = CreateWalletViewController(delegate: interactor)

        presenter.view = viewController

        return viewController
    }

}

protocol CreateWalletViewDelegate {
    func viewDidLoad()
}

protocol CreateWalletViewProtocol: class {
    func show(wordsString: String)
}

protocol CreateWalletPresenterProtocol {
    func show(words: [String])
}

protocol CreateWalletDataProviderProtocol {
    func generateWords() -> [String]?
}

class CreateWalletDataProvider: CreateWalletDataProviderProtocol {
    func generateWords() -> [String]? {
        return try? Mnemonic.generate()
    }
}

import Foundation
import BitcoinKit

class CreateWalletRouter: CreateWalletRouterProtocol {

    private weak var viewController: UIViewController?

    static var viewController: UIViewController {
        let router = CreateWalletRouter()
        let presenter = CreateWalletPresenter()
        let interactor = CreateWalletInteractor(router: router, presenter: presenter, dataProvider: CreateWalletDataProvider())
        let viewController = CreateWalletViewController(delegate: interactor)

        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

    func close() {
        viewController?.dismiss(animated: true)
    }

}

protocol CreateWalletViewDelegate {
    func viewDidLoad()
    func cancelDidTap()
}

protocol CreateWalletViewProtocol: class {
    func show(words: [String])
}

protocol CreateWalletPresenterProtocol {
    func show(words: [String])
    func showError()
}

protocol CreateWalletRouterProtocol {
    func close()
}

protocol CreateWalletDataProviderProtocol {
    func generateWords() -> [String]?
}

class CreateWalletDataProvider: CreateWalletDataProviderProtocol {
    func generateWords() -> [String]? {
        return try? Mnemonic.generate()
    }
}

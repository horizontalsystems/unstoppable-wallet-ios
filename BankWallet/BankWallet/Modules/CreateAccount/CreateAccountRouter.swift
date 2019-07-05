import UIKit

class CreateAccountRouter {
    weak var viewController: UIViewController?
    weak var delegate: ICreateAccountDelegate?
}

extension CreateAccountRouter: ICreateAccountRouter {

    func dismiss(account: Account, coin: Coin) {
        viewController?.dismiss(animated: true) { [weak self] in
            self?.delegate?.onCreate(account: account, coin: coin)
        }
    }

}

extension CreateAccountRouter {

    static func module(coin: Coin, delegate: ICreateAccountDelegate?) -> UIViewController {
        let router = CreateAccountRouter()
        let interactor = CreateAccountInteractor(accountCreator: App.shared.accountCreator)
        let presenter = CreateAccountPresenter(router: router, interactor: interactor, coin: coin)
        let viewController = CreateAccountViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController

        router.viewController = viewController
        router.delegate = delegate

        return viewController
    }

}

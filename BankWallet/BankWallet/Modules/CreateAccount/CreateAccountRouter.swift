import UIKit

class CreateAccountRouter {
    weak var viewController: UIViewController?

    private let delegate: ICreateAccountDelegate

    init(delegate: ICreateAccountDelegate) {
        self.delegate = delegate
    }
}

extension CreateAccountRouter: ICreateAccountRouter {

    func dismiss(account: Account, coin: Coin) {
        viewController?.dismiss(animated: true) { [weak self] in
            self?.delegate.onCreate(account: account, coin: coin)
        }
    }

}

extension CreateAccountRouter {

    static func module(coin: Coin, delegate: ICreateAccountDelegate) -> UIViewController {
        let router = CreateAccountRouter(delegate: delegate)
        let presenter = CreateAccountPresenter(coin: coin, router: router, accountCreator: App.shared.accountCreator)
        let viewController = CreateAccountViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}

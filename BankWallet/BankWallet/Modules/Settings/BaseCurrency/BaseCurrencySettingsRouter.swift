import UIKit

class BaseCurrencySettingsRouter {
    var viewController: UIViewController?
}

extension BaseCurrencySettingsRouter: IBaseCurrencySettingsRouter {

    func dismiss() {
        viewController?.navigationController?.popViewController(animated: true)
    }

}

extension BaseCurrencySettingsRouter {

    static func module() -> UIViewController {
        let router = BaseCurrencySettingsRouter()
        let interactor = BaseCurrencySettingsInteractor(currencyManager: App.shared.currencyManager)
        let presenter = BaseCurrencySettingsPresenter(router: router, interactor: interactor)
        let view = BaseCurrencySettingsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = view
        router.viewController = view

        return view
    }

}

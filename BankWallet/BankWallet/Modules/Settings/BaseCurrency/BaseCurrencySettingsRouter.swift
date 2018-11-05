import UIKit

class BaseCurrencySettingsRouter {
}

extension BaseCurrencySettingsRouter: IBaseCurrencySettingsRouter {
}

extension BaseCurrencySettingsRouter {

    static func module() -> UIViewController {
        let router = BaseCurrencySettingsRouter()
        let interactor = BaseCurrencySettingsInteractor(currencyManager: App.shared.currencyManager)
        let presenter = BaseCurrencySettingsPresenter(router: router, interactor: interactor)
        let view = BaseCurrencySettingsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = view

        return view
    }

}

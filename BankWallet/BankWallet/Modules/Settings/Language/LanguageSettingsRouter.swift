import UIKit
import LanguageKit

class LanguageSettingsRouter {
    weak var viewController: UIViewController?
}

extension LanguageSettingsRouter: ILanguageSettingsRouter {

    func dismiss() {
        viewController?.navigationController?.popViewController(animated: true)
    }

    func reloadAppInterface() {
        UIApplication.shared.keyWindow?.set(newRootController: MainRouter.module(selectedTab: .settings))
    }

}

extension LanguageSettingsRouter {

    static func module() -> UIViewController {
        let router = LanguageSettingsRouter()
        let interactor = LanguageSettingsInteractor(languageManager: LanguageManager.shared)
        let presenter = LanguageSettingsPresenter(router: router, interactor: interactor)
        let view = LanguageSettingsViewController(delegate: presenter)

        presenter.view = view
        router.viewController = view

        return view
    }

}

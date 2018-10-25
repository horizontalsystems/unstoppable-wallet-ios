import UIKit

class LanguageSettingsRouter {
}

extension LanguageSettingsRouter: ILanguageSettingsRouter {

    func reloadAppInterface() {
        if let window = UIApplication.shared.keyWindow {
            UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
                window.rootViewController = MainRouter.module()
            })
        }
    }

}

extension LanguageSettingsRouter {

    static func module() -> UIViewController {
        let router = LanguageSettingsRouter()
        let interactor = LanguageSettingsInteractor(languageManager: App.shared.languageManager, localizationManager: App.shared.localizationManager)
        let presenter = LanguageSettingsPresenter(router: router, interactor: interactor)
        let view = LanguageSettingsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = view

        return view
    }

}

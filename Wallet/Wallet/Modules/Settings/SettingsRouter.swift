import Foundation

class SettingsRouter {
    weak var viewController: UIViewController?
}

extension SettingsRouter: SettingsRouterProtocol {

}

extension SettingsRouter {

    static func module() -> UIViewController {
        let router = SettingsRouter()
        let presenter = SettingsPresenter(router: router)
        let viewController = SettingsViewController(viewDelegate: presenter)

        router.viewController = viewController

        return viewController
    }

}

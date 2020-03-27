import UIKit
import ThemeKit

class IntroRouter {
    weak var viewController: UIViewController?
}

extension IntroRouter: IIntroRouter {

    func showWelcome() {
        viewController?.present(WelcomeScreenRouter.module(), animated: true)
    }

}

extension IntroRouter {

    static func module() -> UIViewController {
        let router = IntroRouter()
        let presenter = IntroPresenter(router: router)
        let viewController = IntroViewController(delegate: presenter)

        router.viewController = viewController

        return viewController
    }

}

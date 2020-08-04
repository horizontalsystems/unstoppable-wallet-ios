import UIKit

class UniswapInfoRouter {
    weak var viewController: UIViewController?
    private var urlManager: IUrlManager

    init(urlManager: IUrlManager) {
        self.urlManager = urlManager
    }

}

extension UniswapInfoRouter: IUniswapInfoRouter {

    func open(url: String) {
        urlManager.open(url: url, from: viewController)
    }

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension UniswapInfoRouter {

    static func module() -> UIViewController {
        let router = UniswapInfoRouter(urlManager: UrlManager(inApp: true))
        let presenter = UniswapInfoPresenter(router: router)
        let viewController = UniswapInfoViewController(delegate: presenter)

        router.viewController = viewController

        return viewController
    }

}

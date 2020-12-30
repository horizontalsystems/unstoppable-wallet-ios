import UIKit

class UniswapInfoRouter {
    weak var viewController: UIViewController?
    private var urlManager: IUrlManager

    init(urlManager: IUrlManager) {
        self.urlManager = urlManager
    }

}

extension UniswapInfoRouter: IInfoRouter {

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
        let presenter = InfoPresenter(router: router, url: "https://uniswap.org/")
        let viewController = InfoViewController(title: "swap.uniswap_info.title".localized, delegate: presenter, sectionDataSource: UniswapInfoSectionDataSource(rowsFactory: InfoRowsFactory()))

        router.viewController = viewController

        return viewController
    }

}

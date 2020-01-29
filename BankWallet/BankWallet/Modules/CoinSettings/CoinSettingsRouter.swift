import UIKit
import ThemeKit

class CoinSettingsRouter {
    weak var viewController: UIViewController?

    private let delegate: ICoinSettingsDelegate?

    init(delegate: ICoinSettingsDelegate? = nil) {
        self.delegate = delegate
    }

}

extension CoinSettingsRouter: ICoinSettingsRouter {

    func notifyConfirm() {
        delegate?.onConfirm()
    }

    func open(url: String) {
        guard let url = URL(string: url) else {
            return
        }

        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

}

extension CoinSettingsRouter {

    static func module(proceedMode: RestoreRouter.ProceedMode, delegate: ICoinSettingsDelegate? = nil) -> UIViewController {
        let router = CoinSettingsRouter(delegate: delegate)
        let interactor = CoinSettingsInteractor(coinSettingsManager: App.shared.coinSettingsManager)
        let presenter = CoinSettingsPresenter(proceedMode: proceedMode, router: router, interactor: interactor)
        let viewController = CoinSettingsViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}

import UIKit

class DataProviderSettingsRouter {
    weak var viewController: UIViewController?
}

extension DataProviderSettingsRouter: IDataProviderSettingsRouter {

    func popViewController() {
        viewController?.navigationController?.popViewController(animated: true)
    }

}

extension DataProviderSettingsRouter {

    static func module(for coin: Coin, transactionHash: String) -> UIViewController {
        let router = DataProviderSettingsRouter()
        let interactor = DataProviderSettingsInteractor(dataProviderManager: App.shared.dataProviderManager, pingManager: PingManager())
        let presenter = DataProviderSettingsPresenter(coin: coin, transactionHash: transactionHash, router: router, interactor: interactor)
        let view = DataProviderSettingsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = view

        router.viewController = view
        return view
    }

}

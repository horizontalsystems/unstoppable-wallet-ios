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

    static func module(for coinCode: String, transactionHash: String) -> UIViewController {
        let router = DataProviderSettingsRouter()
        let interactor = DataProviderSettingsInteractor(dataProviderManager: App.shared.dataProviderManager, pingManager: App.shared.pingManager)
        let presenter = DataProviderSettingsPresenter(coinCode: coinCode, transactionHash: transactionHash, router: router, interactor: interactor)
        let view = DataProviderSettingsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = view

        router.viewController = view
        return view
    }

}

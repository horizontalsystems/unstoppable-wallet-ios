import UIKit

class DataProviderSettingsRouter {
}

extension DataProviderSettingsRouter: IDataProviderSettingsRouter {
}

extension DataProviderSettingsRouter {

    static func module(for coinCode: String) -> UIViewController {
        let router = DataProviderSettingsRouter()
        let interactor = DataProviderSettingsInteractor(dataProviderManager: App.shared.dataProviderManager)
        let presenter = DataProviderSettingsPresenter(coinCode: coinCode, router: router, interactor: interactor)
        let view = DataProviderSettingsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = view

        return view
    }

}

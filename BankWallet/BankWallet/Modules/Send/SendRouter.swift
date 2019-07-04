import UIKit
import ActionSheet

class SendRouter {
    weak var viewController: UIViewController?
}

extension SendRouter: ISendRouter {

    func dismiss() {
        viewController?.dismiss(animated: true)
    }

}

extension SendRouter {

    static func module(coinCode: CoinCode) -> ActionSheetController? {
        guard let adapter = App.shared.adapterManager.adapters.first(where: { $0.wallet.coin.code == coinCode }) else {
            return nil
        }

        let interactorState = SendInteractorState(adapter: adapter)
        let factory = SendStateViewItemFactory()
        let userInput = SendUserInput()

        let router = SendRouter()
        let interactor = SendInteractor(currencyManager: App.shared.currencyManager, rateStorage: App.shared.grdbStorage, localStorage: UserDefaultsStorage.shared, pasteboardManager: App.shared.pasteboardManager, state: interactorState, appConfigProvider: App.shared.appConfigProvider, backgroundManager: App.shared.backgroundManager)
        let presenter = SendPresenter(interactor: interactor, router: router, factory: factory, userInput: userInput)
        let viewController = SendViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}

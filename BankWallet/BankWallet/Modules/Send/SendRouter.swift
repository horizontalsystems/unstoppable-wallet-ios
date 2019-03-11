import UIKit
import GrouviActionSheet

class SendRouter {
    weak var viewController: UIViewController?
}

extension SendRouter: ISendRouter {
}

extension SendRouter {

    static func module(coinCode: CoinCode) -> ActionSheetController? {
        guard let adapter = App.shared.adapterManager.adapters.first(where: { $0.coin.code == coinCode }) else {
            return nil
        }

        let interactorState = SendInteractorState(adapter: adapter)
        let factory = SendStateViewItemFactory()
        let userInput = SendUserInput()
        let feeRateSliderConverter = FeeRateSliderConverter(feeRates: adapter.feeRates)

        let router = SendRouter()
        let interactor = SendInteractor(currencyManager: App.shared.currencyManager, rateStorage: App.shared.grdbStorage, localStorage: App.shared.localStorage, pasteboardManager: App.shared.pasteboardManager, state: interactorState, appConfigProvider: App.shared.appConfigProvider)
        let presenter = SendPresenter(interactor: interactor, router: router, factory: factory, userInput: userInput, feeRateSliderConverter: feeRateSliderConverter)
        let viewController = SendViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}

import UIKit
import ThemeKit
import UniswapKit

class SwapRouter {
    weak var viewController: UIViewController?
}

extension SwapRouter: ISwapRouter {

    func openTokenSelect(accountCoins: Bool, exclude: [Coin], delegate: ICoinSelectDelegate) {
        viewController?.present(SwapTokenSelectRouter.module(accountCoins: accountCoins, exclude: exclude, delegate: delegate), animated: true)
    }

    func showConfirmation(coinIn: Coin, coinOut: Coin, tradeData: TradeData, delegate: ISwapConfirmationDelegate) {
        let confirmationController = SwapConfirmationRouter.module(coinIn: coinIn, coinOut: coinOut, tradeData: tradeData, delegate: delegate)

        viewController?.navigationController?.pushViewController(confirmationController, animated: true)
    }

    func dismiss() {
        viewController?.dismiss(animated: true)
    }

}

extension SwapRouter {

    static func module(wallet: Wallet) -> UIViewController? {
        guard let swapKit = App.shared.swapKitManager.kit(account: wallet.account) else {
            return nil
        }

        let decimalParser = SendAmountDecimalParser()
        let swapTokenManager = SwapTokenManager(coinManager: App.shared.coinManager, walletManager: App.shared.walletManager, adapterManager: App.shared.adapterManager)

        let router = SwapRouter()
        let interactor = SwapInteractor(swapKit: swapKit, swapTokenManager: swapTokenManager)
        let presenter = SwapPresenter(interactor: interactor, router: router, factory: SwapViewItemFactory(), decimalParser: decimalParser, coinIn: wallet.coin)
        let viewController = SwapViewController(delegate: presenter)

        presenter.view = viewController
        interactor.delegate = presenter
        router.viewController = viewController

        return ThemeNavigationController(rootViewController: viewController)
    }

}

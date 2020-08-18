import UIKit
import ThemeKit
import EthereumKit
import UniswapKit

class SwapRouter {
    weak var viewController: UIViewController?
}

extension SwapRouter: ISwapRouter {

    func openTokenSelect(accountCoins: Bool, exclude: [Coin], delegate: ICoinSelectDelegate) {
        viewController?.present(SwapTokenSelectRouter.module(accountCoins: accountCoins, exclude: exclude, delegate: delegate), animated: true)
    }

    func showApprove(delegate: ISwapApproveDelegate, coin: Coin, spenderAddress: Address, amount: Decimal) {
        guard let approveController = SwapApproveRouter.module(coin: coin, spenderAddress: spenderAddress, amount: amount, delegate: delegate) else {
            return
        }
        viewController?.present(approveController, animated: true)
    }

    func showConfirmation(coinIn: Coin, coinOut: Coin, tradeData: TradeData, delegate: ISwapConfirmationDelegate) {
        let confirmationController = SwapConfirmationRouter.module(coinIn: coinIn, coinOut: coinOut, tradeData: tradeData, delegate: delegate)

        viewController?.navigationController?.pushViewController(confirmationController, animated: true)
    }

    func showUniswapInfo() {
        let module = UniswapInfoRouter.module()
        viewController?.present(ThemeNavigationController(rootViewController: module), animated: true)
    }

    func dismiss() {
        viewController?.dismiss(animated: true)
    }

}

extension SwapRouter {

    static func module(wallet: Wallet) -> UIViewController? {
        guard let ethereumKit = try? App.shared.ethereumKitManager.ethereumKit(account: wallet.account) else {
            return nil
        }

        let decimalParser = SendAmountDecimalParser()
        let swapTokenManager = SwapTokenManager(coinManager: App.shared.coinManager, walletManager: App.shared.walletManager, adapterManager: App.shared.adapterManager)

        let router = SwapRouter()
        let interactor = SwapInteractor(swapKit: UniswapKit.Kit.instance(ethereumKit: ethereumKit), swapTokenManager: swapTokenManager)
        let presenter = SwapPresenter(interactor: interactor, router: router, viewItemFactory: SwapViewItemFactory(), stateFactory: SwapFactory(), decimalParser: decimalParser, coinIn: wallet.coin)
        let viewController = SwapViewController(delegate: presenter)

        presenter.view = viewController
        interactor.delegate = presenter
        router.viewController = viewController

        return ThemeNavigationController(rootViewController: viewController)
    }

}

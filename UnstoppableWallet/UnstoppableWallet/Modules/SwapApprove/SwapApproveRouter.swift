import UIKit
import ThemeKit
import EthereumKit

class SwapApproveRouter {
    weak var viewController: UIViewController?
}

extension SwapApproveRouter: ISwapApproveRouter {

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension SwapApproveRouter {

    static func module(coin: Coin, spenderAddress: Address, amount: Decimal, delegate: ISwapApproveDelegate) -> UIViewController? {
        guard   let wallet = App.shared.walletManager.wallets.first(where: { $0.coin == coin }),
                let adapter = App.shared.adapterManager.adapter(for: wallet),
                let feeRateProvider = App.shared.feeRateProviderFactory.provider(coin: coin) else {

            return nil
        }

        guard let feeAdapter = FeeAdapterFactory()
                .swapAdapter(adapter: adapter) else {

            return nil
        }

        guard let sendAdapter = adapter as? Erc20Adapter else {
            return nil
        }

        let feeModule = FeeModule.module()
        let factory = SwapApproveViewItemFactory(feeModule: feeModule)

        let router = SwapApproveRouter()
        let interactor = SwapApproveInteractor(feeAdapter: feeAdapter, provider: feeRateProvider, sendAdapter: sendAdapter)
        let presenter = SwapApprovePresenter(interactor: interactor, router: router, factory: factory, delegate: delegate, coin: coin, amount: amount, spenderAddress: spenderAddress)

        let viewController = SwapApproveViewController(delegate: presenter)

        presenter.view = viewController
        interactor.delegate = presenter
        router.viewController = viewController

        return viewController.toBottomSheet
    }

}

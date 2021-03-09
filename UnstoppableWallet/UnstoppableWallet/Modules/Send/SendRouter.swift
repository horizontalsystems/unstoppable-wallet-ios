import UIKit
import ThemeKit
import CoinKit

class SendRouter {
    weak var viewController: UIViewController?
}

extension SendRouter: ISendRouter {

    func showConfirmation(viewItems: [ISendConfirmationViewItemNew], delegate: ISendConfirmationDelegate) {
        let confirmationController = SendConfirmationRouter.module(viewItems: viewItems, delegate: delegate)
        viewController?.navigationController?.pushViewController(confirmationController, animated: true)
    }

    func dismiss() {
        viewController?.dismiss(animated: true)
    }

}

extension SendRouter {

    static func module(wallet: Wallet) -> UIViewController? {
        guard let adapter = App.shared.adapterManager.adapter(for: wallet) else {
            return nil
        }

        let router = SendRouter()

        var partialModule: (ISendHandler, [UIView], [ISendSubRouter])?

        switch adapter {
        case let adapter as ISendBitcoinAdapter:
            partialModule = module(coin: wallet.coin, adapter: adapter)
        case let adapter as ISendDashAdapter:
            partialModule = module(coin: wallet.coin, adapter: adapter)
        case let adapter as ISendEthereumAdapter:
            return SendEvmModule.viewController(coin: wallet.coin, adapter: adapter)
        case let adapter as ISendBinanceAdapter:
            partialModule = module(coin: wallet.coin, adapter: adapter)
        case let adapter as ISendZcashAdapter:
            partialModule = module(coin: wallet.coin, adapter: adapter)
        default: ()
        }

        guard let (handler, subViews, subRouters) = partialModule else {
            return nil
        }

        let interactor = SendInteractor(reachabilityManager: App.shared.reachabilityManager, rateManager: App.shared.rateManager, currencyKit: App.shared.currencyKit, localStorage: App.shared.localStorage)
        let presenter = SendPresenter(coin: wallet.coin, handler: handler, interactor: interactor, router: router, logger: App.shared.logger.scoped(with: "Send"))
        let viewController = SendViewController(delegate: presenter, views: subViews)

        interactor.delegate = presenter
        presenter.view = viewController
        handler.delegate = presenter

        router.viewController = viewController
        subRouters.forEach { $0.viewController = viewController }

        return ThemeNavigationController(rootViewController: viewController)
    }

    private static func module(coin: Coin, adapter: ISendBitcoinAdapter) -> (ISendHandler, [UIView], [ISendSubRouter])? {
        let interactor = SendBitcoinInteractor(adapter: adapter, transactionDataSortModeSettingsManager: App.shared.transactionDataSortModeSettingManager, localStorage: App.shared.localStorage)

        var views = [UIView]()
        var routers = [ISendSubRouter]()

        let (amountView, amountModule) = SendAmountRouter.module(coin: coin)
        views.append(amountView)

        let (addressView, addressModule, addressRouter) = SendAddressRouter.module(coin: coin)
        views.append(addressView)
        routers.append(addressRouter)

        var hodlerModule: ISendHodlerModule?

        let (feeView, feeModule) = SendFeeRouter.module(coin: coin)
        views.append(feeView)

        guard let (feePriorityView, feePriorityModule, feePriorityRouter) = SendFeePriorityRouter.module(coin: coin, customPriorityUnit: .satoshi) else {
            return nil
        }
        if let view = feePriorityView {
            views.append(view)
        }
        routers.append(feePriorityRouter)

        if interactor.lockTimeEnabled && coin.type == .bitcoin {
            let (hodlerView, module, hodlerRouter) = SendHodlerRouter.module()
            hodlerModule = module
            views.append(hodlerView)
            routers.append(hodlerRouter)
        }

        let presenter = SendBitcoinHandler(
                interactor: interactor,
                amountModule: amountModule,
                addressModule: addressModule,
                feeModule: feeModule,
                feePriorityModule: feePriorityModule,
                hodlerModule: hodlerModule
        )

        interactor.delegate = presenter

        amountModule.delegate = presenter
        addressModule.delegate = presenter
        feePriorityModule.delegate = presenter
        hodlerModule?.delegate = presenter

        return (presenter, views, routers)
    }

    private static func module(coin: Coin, adapter: ISendDashAdapter) -> (ISendHandler, [UIView], [ISendSubRouter]) {
        let (amountView, amountModule) = SendAmountRouter.module(coin: coin)
        let (addressView, addressModule, addressRouter) = SendAddressRouter.module(coin: coin)
        let (feeView, feeModule) = SendFeeRouter.module(coin: coin)

        let interactor = SendDashInteractor(adapter: adapter, transactionDataSortModeSettingsManager: App.shared.transactionDataSortModeSettingManager)
        let presenter = SendDashHandler(interactor: interactor, amountModule: amountModule, addressModule: addressModule, feeModule: feeModule)

        interactor.delegate = presenter

        amountModule.delegate = presenter
        addressModule.delegate = presenter

        return (presenter, [amountView, addressView, feeView], [addressRouter])
    }

    private static func module(coin: Coin, adapter: ISendBinanceAdapter) -> (ISendHandler, [UIView], [ISendSubRouter]) {
        let (amountView, amountModule) = SendAmountRouter.module(coin: coin)
        let (addressView, addressModule, addressRouter) = SendAddressRouter.module(coin: coin)
        let (memoView, memoModule) = SendMemoRouter.module()
        let (feeView, feeModule) = SendFeeRouter.module(coin: coin)

        let interactor = SendBinanceInteractor(adapter: adapter)
        let presenter = SendBinanceHandler(interactor: interactor, amountModule: amountModule, addressModule: addressModule, memoModule: memoModule, feeModule: feeModule)

        amountModule.delegate = presenter
        addressModule.delegate = presenter

        return (presenter, [amountView, addressView, memoView, feeView], [addressRouter])
    }

    private static func module(coin: Coin, adapter: ISendZcashAdapter) -> (ISendHandler, [UIView], [ISendSubRouter]) {
        let (amountView, amountModule) = SendAmountRouter.module(coin: coin)
        let (addressView, addressModule, addressRouter) = SendAddressRouter.module(coin: coin, isResolutionEnabled: false)
        let (memoView, memoModule) = SendMemoRouter.module()
        let (feeView, feeModule) = SendFeeRouter.module(coin: coin)

        let interactor = SendZcashInteractor(adapter: adapter)
        let presenter = SendZcashHandler(interactor: interactor, amountModule: amountModule, addressModule: addressModule, memoModule: memoModule, feeModule: feeModule)

        amountModule.delegate = presenter
        addressModule.delegate = presenter

        return (presenter, [amountView, addressView, memoView, feeView], [addressRouter])
    }

}

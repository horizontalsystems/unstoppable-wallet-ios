import UIKit

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
            partialModule = module(coin: wallet.coin, adapter: adapter)
        case let adapter as ISendEosAdapter:
            partialModule = module(coin: wallet.coin, adapter: adapter)
        case let adapter as ISendBinanceAdapter:
            partialModule = module(coin: wallet.coin, adapter: adapter)
        default: ()
        }

        guard let (handler, subViews, subRouters) = partialModule else {
            return nil
        }

        let interactor = SendInteractor()
        let presenter = SendPresenter(coin: wallet.coin, handler: handler, interactor: interactor, router: router)
        let viewController = SendViewController(delegate: presenter, views: subViews)

        interactor.delegate = presenter
        presenter.view = viewController
        handler.delegate = presenter

        router.viewController = viewController
        subRouters.forEach { $0.viewController = viewController }

        return WalletNavigationController(rootViewController: viewController)
    }

    private static func module(coin: Coin, adapter: ISendBitcoinAdapter) -> (ISendHandler, [UIView], [ISendSubRouter])? {
        let interactor = SendBitcoinInteractor(adapter: adapter, localStorage: App.shared.localStorage)

        var views = [UIView]()
        var routers = [ISendSubRouter]()

        let (amountView, amountModule) = SendAmountRouter.module(coin: coin)
        views.append(amountView)

        let (addressView, addressModule, addressRouter) = SendAddressRouter.module(coin: coin)
        views.append(addressView)
        routers.append(addressRouter)

        guard let (feePriorityView, feePriorityModule, feePriorityRouter) = SendFeePriorityRouter.module(coin: coin) else {
            return nil
        }
        views.append(feePriorityView)
        routers.append(feePriorityRouter)

        var hodlerModule: ISendHodlerModule?

        if interactor.lockTimeEnabled && coin.type == .bitcoin {
            let (hodlerView, module, hodlerRouter) = SendHodlerRouter.module()
            hodlerModule = module
            views.append(hodlerView)
            routers.append(hodlerRouter)
        }

        let (feeView, feeModule) = SendFeeRouter.module(coin: coin)
        views.append(feeView)

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
        feeModule.delegate = presenter
        feePriorityModule.delegate = presenter
        hodlerModule?.delegate = presenter

        return (presenter, views, routers)
    }

    private static func module(coin: Coin, adapter: ISendDashAdapter) -> (ISendHandler, [UIView], [ISendSubRouter]) {
        let (amountView, amountModule) = SendAmountRouter.module(coin: coin)
        let (addressView, addressModule, addressRouter) = SendAddressRouter.module(coin: coin)
        let (feeView, feeModule) = SendFeeRouter.module(coin: coin)

        let interactor = SendDashInteractor(adapter: adapter)
        let presenter = SendDashHandler(interactor: interactor, amountModule: amountModule, addressModule: addressModule, feeModule: feeModule)

        interactor.delegate = presenter

        amountModule.delegate = presenter
        addressModule.delegate = presenter
        feeModule.delegate = presenter

        return (presenter, [amountView, addressView, feeView], [addressRouter])
    }

    private static func module(coin: Coin, adapter: ISendEthereumAdapter) -> (ISendHandler, [UIView], [ISendSubRouter])? {
        let (amountView, amountModule) = SendAmountRouter.module(coin: coin)
        let (addressView, addressModule, addressRouter) = SendAddressRouter.module(coin: coin)
        let (feeView, feeModule) = SendFeeRouter.module(coin: coin)

        guard let (feePriorityView, feePriorityModule, feePriorityRouter) = SendFeePriorityRouter.module(coin: coin) else {
            return nil
        }

        let interactor = SendEthereumInteractor(adapter: adapter)
        let presenter = SendEthereumHandler(interactor: interactor, amountModule: amountModule, addressModule: addressModule, feeModule: feeModule, feePriorityModule: feePriorityModule)

        amountModule.delegate = presenter
        addressModule.delegate = presenter
        feeModule.delegate = presenter
        feePriorityModule.delegate = presenter

        return (presenter, [amountView, addressView, feePriorityView, feeView], [addressRouter, feePriorityRouter])
    }

    private static func module(coin: Coin, adapter: ISendEosAdapter) -> (ISendHandler, [UIView], [ISendSubRouter]) {
        let (amountView, amountModule) = SendAmountRouter.module(coin: coin)
        let (accountView, accountModule, accountRouter) = SendAccountRouter.module()
        let (memoView, memoModule) = SendMemoRouter.module()

        let interactor = SendEosInteractor(adapter: adapter)
        let presenter = SendEosHandler(interactor: interactor, amountModule: amountModule, accountModule: accountModule, memoModule: memoModule)

        amountModule.delegate = presenter
        accountModule.delegate = presenter

        return (presenter, [amountView, accountView, memoView], [accountRouter])
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
        feeModule.delegate = presenter

        return (presenter, [amountView, addressView, memoView, feeView], [addressRouter])
    }

}

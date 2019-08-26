import UIKit

class SendRouter {
    weak var viewController: UINavigationController?
}

extension SendRouter: ISendRouter {

    func showConfirmation(item: SendConfirmationViewItem, delegate: ISendConfirmationDelegate) {
        let confirmationController = SendConfirmationRouter.module(item: item, delegate: delegate)
        viewController?.pushViewController(confirmationController, animated: true)
    }

    func scanQrCode(delegate: IScanQrCodeDelegate) {
        let scanController = ScanQRController(delegate: delegate)
        viewController?.present(scanController, animated: true)
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

        var partialModule: (ISendViewDelegate, [UIView])?

        switch adapter {
        case let adapter as ISendBitcoinAdapter:
            partialModule = module(coin: wallet.coin, adapter: adapter, router: router)
        case let adapter as ISendDashAdapter:
            partialModule = module(coin: wallet.coin, adapter: adapter, router: router)
        case let adapter as ISendEthereumAdapter:
            partialModule = module(coin: wallet.coin, adapter: adapter, router: router)
        case let adapter as ISendEosAdapter:
            partialModule = module(coin: wallet.coin, adapter: adapter, router: router)
        case let adapter as ISendBinanceAdapter:
            partialModule = module(coin: wallet.coin, adapter: adapter, router: router)
        default: ()
        }

        guard let (presenter, subViews) = partialModule else {
            return nil
        }

        let viewController = SendViewController(delegate: presenter, views: subViews)

        presenter.view = viewController

        let navigationController = WalletNavigationController(rootViewController: viewController)
        router.viewController = navigationController
        return navigationController
    }

    private static func module(coin: Coin, adapter: ISendBitcoinAdapter, router: ISendRouter) -> (ISendViewDelegate, [UIView])? {
        let (amountView, amountModule) = SendAmountRouter.module(coin: coin)
        let (addressView, addressModule) = SendAddressRouter.module(coin: coin)
        let (feeView, feeModule) = SendFeeRouter.module(coin: coin)

        guard let (feePriorityView, feePriorityModule) = SendFeePriorityRouter.module(coin: coin, mainRouter: router) else {
            return nil
        }

        let interactor = SendBitcoinInteractor(adapter: adapter)
        let presenter = SendBitcoinPresenter(coin: coin, interactor: interactor, router: router, confirmationFactory: SendConfirmationItemFactory(), amountModule: amountModule, addressModule: addressModule, feeModule: feeModule, feePriorityModule: feePriorityModule)

        interactor.delegate = presenter

        amountModule.delegate = presenter
        addressModule.delegate = presenter
        feeModule.delegate = presenter
        feePriorityModule.delegate = presenter

        return (presenter, [amountView, addressView, feePriorityView, feeView])
    }

    private static func module(coin: Coin, adapter: ISendDashAdapter, router: ISendRouter) -> (ISendViewDelegate, [UIView]) {
        let (amountView, amountModule) = SendAmountRouter.module(coin: coin)
        let (addressView, addressModule) = SendAddressRouter.module(coin: coin)
        let (feeView, feeModule) = SendFeeRouter.module(coin: coin)

        let interactor = SendDashInteractor(adapter: adapter)
        let presenter = SendDashPresenter(coin: coin, interactor: interactor, router: router, confirmationFactory: SendConfirmationItemFactory(), amountModule: amountModule, addressModule: addressModule, feeModule: feeModule)

        interactor.delegate = presenter

        amountModule.delegate = presenter
        addressModule.delegate = presenter
        feeModule.delegate = presenter

        return (presenter, [amountView, addressView, feeView])
    }

    private static func module(coin: Coin, adapter: ISendEthereumAdapter, router: ISendRouter) -> (ISendViewDelegate, [UIView])? {
        let (amountView, amountModule) = SendAmountRouter.module(coin: coin)
        let (addressView, addressModule) = SendAddressRouter.module(coin: coin)
        let (feeView, feeModule) = SendFeeRouter.module(coin: coin)

        guard let (feePriorityView, feePriorityModule) = SendFeePriorityRouter.module(coin: coin, mainRouter: router) else {
            return nil
        }

        let interactor = SendEthereumInteractor(adapter: adapter)
        let presenter = SendEthereumPresenter(coin: coin, interactor: interactor, router: router, confirmationFactory: SendConfirmationItemFactory(), amountModule: amountModule, addressModule: addressModule, feeModule: feeModule, feePriorityModule: feePriorityModule)

        interactor.delegate = presenter

        amountModule.delegate = presenter
        addressModule.delegate = presenter
        feeModule.delegate = presenter
        feePriorityModule.delegate = presenter

        return (presenter, [amountView, addressView, feePriorityView, feeView])
    }

    private static func module(coin: Coin, adapter: ISendEosAdapter, router: ISendRouter) -> (ISendViewDelegate, [UIView]) {
        let (amountView, amountModule) = SendAmountRouter.module(coin: coin)
        let (accountView, accountModule) = SendAccountRouter.module()

        let interactor = SendEosInteractor(adapter: adapter)
        let presenter = SendEosPresenter(coin: coin, interactor: interactor, router: router, confirmationFactory: SendConfirmationItemFactory(), amountModule: amountModule, accountModule: accountModule)

        interactor.delegate = presenter

        amountModule.delegate = presenter
        accountModule.delegate = presenter

        return (presenter, [amountView, accountView])
    }

    private static func module(coin: Coin, adapter: ISendBinanceAdapter, router: ISendRouter) -> (ISendViewDelegate, [UIView]) {
        let (amountView, amountModule) = SendAmountRouter.module(coin: coin)
        let (addressView, addressModule) = SendAddressRouter.module(coin: coin)
        let (feeView, feeModule) = SendFeeRouter.module(coin: coin)

        let interactor = SendBinanceInteractor(adapter: adapter)
        let presenter = SendBinancePresenter(coin: coin, interactor: interactor, router: router, confirmationFactory: SendConfirmationItemFactory(), amountModule: amountModule, addressModule: addressModule, feeModule: feeModule)

        interactor.delegate = presenter

        amountModule.delegate = presenter
        addressModule.delegate = presenter
        feeModule.delegate = presenter

        return (presenter, [amountView, addressView, feeView])
    }

}

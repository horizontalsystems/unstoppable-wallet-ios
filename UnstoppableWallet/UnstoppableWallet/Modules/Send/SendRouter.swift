import UIKit
import ThemeKit
import MarketKit

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

        let platformCoin = wallet.platformCoin

        switch adapter {
        case let adapter as ISendBitcoinAdapter:
            partialModule = module(platformCoin: platformCoin, adapter: adapter)
        case let adapter as ISendDashAdapter:
            partialModule = module(platformCoin: platformCoin, adapter: adapter)
        case let adapter as ISendEthereumAdapter:
            return SendEvmModule.viewController(platformCoin: platformCoin, adapter: adapter)
        case let adapter as ISendBinanceAdapter:
            partialModule = module(platformCoin: platformCoin, adapter: adapter)
        case let adapter as ISendZcashAdapter:
            partialModule = module(platformCoin: platformCoin, adapter: adapter)
        default: ()
        }

        guard let (handler, subViews, subRouters) = partialModule else {
            return nil
        }

        let interactor = SendInteractor(reachabilityManager: App.shared.reachabilityManager, marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit, localStorage: App.shared.localStorage)
        let presenter = SendPresenter(platformCoin: platformCoin, handler: handler, interactor: interactor, router: router, logger: App.shared.logger.scoped(with: "Send"))
        let viewController = SendViewController(delegate: presenter, views: subViews)

        interactor.delegate = presenter
        presenter.view = viewController
        handler.delegate = presenter

        router.viewController = viewController
        subRouters.forEach { $0.viewController = viewController }

        return ThemeNavigationController(rootViewController: viewController)
    }

    private static func module(platformCoin: PlatformCoin, adapter: ISendBitcoinAdapter) -> (ISendHandler, [UIView], [ISendSubRouter])? {
        let interactor = SendBitcoinInteractor(adapter: adapter, transactionDataSortModeSettingsManager: App.shared.transactionDataSortModeSettingManager, localStorage: App.shared.localStorage)

        var views = [UIView]()
        var routers = [ISendSubRouter]()

        let (amountView, amountModule) = SendAmountRouter.module(platformCoin: platformCoin)
        views.append(amountView)

        let addressParserChain = AddressParserChain()
        let bitcoinParserItem = BitcoinAddressParserItem(adapter: adapter)
        addressParserChain.append(handler: bitcoinParserItem)
        addressParserChain.append(handler: UDNAddressParserItem(coinCode: "BTC", platformCoinCode: nil, chain: nil))

        let (addressView, addressModule, addressRouter) = SendAddressRouter.module(platformCoin: platformCoin, addressParserChain: addressParserChain)
        views.append(addressView)
        routers.append(addressRouter)

        var hodlerModule: ISendHodlerModule?

        let (feeView, feeModule) = SendFeeRouter.module(platformCoin: platformCoin)
        views.append(feeView)

        guard let (feePriorityView, feePriorityModule, feePriorityRouter) = SendFeePriorityRouter.module(platformCoin: platformCoin, customPriorityUnit: .satoshi) else {
            return nil
        }
        if let view = feePriorityView {
            views.append(view)
        }
        routers.append(feePriorityRouter)

        if interactor.lockTimeEnabled && platformCoin.coinType == .bitcoin {
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
                hodlerModule: hodlerModule,
                bitcoinAddressParser: bitcoinParserItem
        )

        interactor.delegate = presenter

        amountModule.delegate = presenter
        addressModule.delegate = presenter
        feePriorityModule.delegate = presenter
        hodlerModule?.delegate = presenter

        return (presenter, views, routers)
    }

    private static func module(platformCoin: PlatformCoin, adapter: ISendDashAdapter) -> (ISendHandler, [UIView], [ISendSubRouter]) {
        let (amountView, amountModule) = SendAmountRouter.module(platformCoin: platformCoin)

        let addressParserChain = AddressParserChain()
        let dashParserItem = DashAddressParserItem(adapter: adapter)
        addressParserChain.append(handler: dashParserItem)

        let (addressView, addressModule, addressRouter) = SendAddressRouter.module(platformCoin: platformCoin, addressParserChain: addressParserChain)
        let (feeView, feeModule) = SendFeeRouter.module(platformCoin: platformCoin)

        let interactor = SendDashInteractor(adapter: adapter, transactionDataSortModeSettingsManager: App.shared.transactionDataSortModeSettingManager)
        let presenter = SendDashHandler(interactor: interactor, amountModule: amountModule, addressModule: addressModule, feeModule: feeModule)

        interactor.delegate = presenter

        amountModule.delegate = presenter
        addressModule.delegate = presenter

        return (presenter, [amountView, addressView, feeView], [addressRouter])
    }

    private static func module(platformCoin: PlatformCoin, adapter: ISendBinanceAdapter) -> (ISendHandler, [UIView], [ISendSubRouter]) {
        let (amountView, amountModule) = SendAmountRouter.module(platformCoin: platformCoin)

        let addressParserChain = AddressParserChain()
        let binanceParserItem = BinanceAddressParserItem(adapter: adapter)
        addressParserChain.append(handler: binanceParserItem)

        let (addressView, addressModule, addressRouter) = SendAddressRouter.module(platformCoin: platformCoin, addressParserChain: addressParserChain)
        let (memoView, memoModule) = SendMemoRouter.module()
        let (feeView, feeModule) = SendFeeRouter.module(platformCoin: platformCoin)

        let interactor = SendBinanceInteractor(adapter: adapter)
        let presenter = SendBinanceHandler(interactor: interactor, amountModule: amountModule, addressModule: addressModule, memoModule: memoModule, feeModule: feeModule)

        amountModule.delegate = presenter
        addressModule.delegate = presenter

        return (presenter, [amountView, addressView, memoView, feeView], [addressRouter])
    }

    private static func module(platformCoin: PlatformCoin, adapter: ISendZcashAdapter) -> (ISendHandler, [UIView], [ISendSubRouter]) {
        let (amountView, amountModule) = SendAmountRouter.module(platformCoin: platformCoin)

        let addressParserChain = AddressParserChain()
        let zCashParserItem = ZcashAddressParserItem(adapter: adapter)
        addressParserChain.append(handler: zCashParserItem)

        let (addressView, addressModule, addressRouter) = SendAddressRouter.module(platformCoin: platformCoin, addressParserChain: addressParserChain)
        let (memoView, memoModule) = SendMemoRouter.module()
        let (feeView, feeModule) = SendFeeRouter.module(platformCoin: platformCoin)

        let interactor = SendZcashInteractor(adapter: adapter)
        let presenter = SendZcashHandler(interactor: interactor, amountModule: amountModule, addressModule: addressModule, memoModule: memoModule, feeModule: feeModule, zCashAddressParser: zCashParserItem)

        amountModule.delegate = presenter
        addressModule.delegate = presenter

        return (presenter, [amountView, addressView, memoView, feeView], [addressRouter])
    }

}

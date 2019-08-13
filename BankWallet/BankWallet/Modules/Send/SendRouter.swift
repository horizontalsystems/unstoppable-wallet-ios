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

    static func module(coinCode: CoinCode) -> UIViewController? {
        guard let wallet = App.shared.walletManager.wallets.first(where: { $0.coin.code == coinCode }),
              let adapter = App.shared.adapterManager.adapter(for: wallet) else {
            return nil
        }

        if let bitcoinAdapter = adapter as? ISendBitcoinAdapter {
            return SendRouter.module(wallet: wallet, adapter: bitcoinAdapter)
        }

        if let ethereumAdapter = adapter as? ISendEthereumAdapter {
            return SendRouter.module(wallet: wallet, adapter: ethereumAdapter)
        }

        return nil
    }

    private static func module(wallet: Wallet, adapter: ISendBitcoinAdapter) -> UIViewController? {
        guard let feeRateProvider = App.shared.feeRateProviderFactory.provider(coin: wallet.coin) else {
            return nil
        }

        let (amountView, amountModule) = SendAmountRouter.module(coin: wallet.coin)
        let (addressView, addressModule) = SendAddressRouter.module(addressParser: App.shared.addressParserFactory.parser(coin: wallet.coin))
        let (feeView, feeModule) = SendFeeRouter.module(coin: wallet.coin)
        let (feeSliderView, feeSliderModule) = SendFeeSliderRouter.module(feeRateProvider: feeRateProvider)

        let router = SendRouter()
        let interactor = SendBitcoinInteractor(wallet: wallet, adapter: adapter)
        let presenter = SendBitcoinPresenter(interactor: interactor, router: router, confirmationFactory: SendConfirmationItemFactory(), amountModule: amountModule, addressModule: addressModule, feeModule: feeModule, feeSliderModule: feeSliderModule)

        let viewController = SendViewController(delegate: presenter, views: [amountView, addressView, feeView, feeSliderView])

        presenter.view = viewController
        interactor.delegate = presenter

        amountModule.delegate = presenter
        addressModule.delegate = presenter
        feeModule.delegate = presenter
        feeSliderModule.delegate = presenter

        let navigationController = WalletNavigationController(rootViewController: viewController)
        router.viewController = navigationController
        return navigationController
    }

    private static func module(wallet: Wallet, adapter: ISendEthereumAdapter) -> UIViewController? {
        guard let feeRateProvider = App.shared.feeRateProviderFactory.provider(coin: wallet.coin) else {
            return nil
        }

        let (amountView, amountModule) = SendAmountRouter.module(coin: wallet.coin)
        let (addressView, addressModule) = SendAddressRouter.module(addressParser: App.shared.addressParserFactory.parser(coin: wallet.coin))
        let (feeView, feeModule) = SendFeeRouter.module(coin: wallet.coin)
        let (feeSliderView, feeSliderModule) = SendFeeSliderRouter.module(feeRateProvider: feeRateProvider)

        let router = SendRouter()
        let interactor = SendEthereumInteractor(wallet: wallet, adapter: adapter)
        let presenter = SendEthereumPresenter(interactor: interactor, router: router, confirmationFactory: SendConfirmationItemFactory(), amountModule: amountModule, addressModule: addressModule, feeModule: feeModule, feeSliderModule: feeSliderModule)

        let viewController = SendViewController(delegate: presenter, views: [amountView, addressView, feeView, feeSliderView])

        presenter.view = viewController
        interactor.delegate = presenter

        amountModule.delegate = presenter
        addressModule.delegate = presenter
        feeModule.delegate = presenter
        feeSliderModule.delegate = presenter

        let navigationController = WalletNavigationController(rootViewController: viewController)
        router.viewController = navigationController
        return navigationController
    }

}

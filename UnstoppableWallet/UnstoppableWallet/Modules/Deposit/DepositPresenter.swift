import UIKit

class DepositPresenter {
    weak var view: IDepositView?

    private let interactor: IDepositInteractor
    private let router: IDepositRouter

    private let coin: Coin
    private let address: String

    init(coin: Coin, interactor: IDepositInteractor, router: IDepositRouter) {
        self.coin = coin
        self.interactor = interactor
        self.router = router

        address = interactor.address
    }

}

extension DepositPresenter: IDepositViewDelegate {

    func onLoad() {
        let viewItem = DepositModule.AddressViewItem(
                coinTitle: coin.title,
                coinCode: coin.code,
                blockchainType: coin.type.blockchainType,
                address: address,
                additionalInfo: interactor.derivationSetting(coinType: coin.type)?.derivation.addressType
        )

        view?.set(viewItem: viewItem)
    }

    func onTapAddress() {
        interactor.copy(address: address)
        view?.showCopied()
    }

    func onTapShare() {
        router.showShare(address: address)
    }

    func onTapClose() {
        router.close()
    }

}

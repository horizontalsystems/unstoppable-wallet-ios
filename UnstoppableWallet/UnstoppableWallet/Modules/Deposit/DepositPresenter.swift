import UIKit
import CoinKit

class DepositPresenter {
    weak var view: IDepositView?

    private let interactor: IDepositInteractor
    private let router: IDepositRouter

    private let wallet: Wallet
    private let address: String

    init(wallet: Wallet, interactor: IDepositInteractor, router: IDepositRouter) {
        self.wallet = wallet
        self.interactor = interactor
        self.router = router

        address = interactor.address
    }

}

extension DepositPresenter: IDepositViewDelegate {

    func onLoad() {
        let viewItem = DepositModule.AddressViewItem(
                coinTitle: wallet.coin.title,
                coinCode: wallet.coin.code,
                coinType: wallet.coin.type,
                address: address,
                additionalInfo: wallet.configuredCoin.settings.derivation?.addressType
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

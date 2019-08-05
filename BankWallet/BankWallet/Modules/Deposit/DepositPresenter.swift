import UIKit

class DepositPresenter {
    weak var view: IDepositView?

    private let interactor: IDepositInteractor
    private let router: IDepositRouter

    let addressItems: [AddressItem]

    init(interactor: IDepositInteractor, router: IDepositRouter, coin: Coin?) {
        self.interactor = interactor
        self.router = router

        addressItems = interactor.adapters(forCoin: coin).map {
            AddressItem(coin: $0.wallet.coin, address: $0.receiveAddress)
        }
    }

}

extension DepositPresenter: IDepositInteractorDelegate {
}

extension DepositPresenter: IDepositViewDelegate {

    func onCopy(index: Int) {
        interactor.copy(address: addressItems[index].address)
        view?.showCopied()
    }

    func onShare(index: Int) {
        router.share(address: addressItems[index].address)
    }

}

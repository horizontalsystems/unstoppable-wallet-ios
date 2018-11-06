import UIKit

class DepositPresenter {
    private let interactor: IDepositInteractor
    private let router: IDepositRouter

    weak var view: IDepositView?

    init(interactor: IDepositInteractor, router: IDepositRouter) {
        self.interactor = interactor
        self.router = router
    }

}

extension DepositPresenter: IDepositInteractorDelegate {
}

extension DepositPresenter: IDepositViewDelegate {

    func addressItems(forCoin coin: Coin?) -> [AddressItem] {
        return interactor.wallets(forCoin: coin).map {
            AddressItem(address: $0.adapter.receiveAddress, coin: $0.coin)
        }
    }

    func onCopy(addressItem: AddressItem) {
        interactor.copy(address: addressItem.address)
        view?.showCopied()
    }

}

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

    func addressItems(forCoin coinCode: CoinCode?) -> [AddressItem] {
        return interactor.wallets(forCoin: coinCode).map {
            AddressItem(title: $0.title, address: $0.adapter.receiveAddress, coinCode: $0.coinCode)
        }
    }

    func onCopy(addressItem: AddressItem) {
        interactor.copy(address: addressItem.address)
        view?.showCopied()
    }

    func onShare(addressItem: AddressItem) {
        router.share(address: addressItem.address)
    }

}

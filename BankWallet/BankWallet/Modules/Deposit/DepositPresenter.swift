import UIKit

class DepositPresenter {
    weak var view: IDepositView?

    private let interactor: IDepositInteractor
    private let router: IDepositRouter

    let addressItems: [AddressItem]

    init(interactor: IDepositInteractor, router: IDepositRouter, wallet: Wallet?) {
        self.interactor = interactor
        self.router = router

        let wallets = wallet.map{ [$0] } ?? interactor.wallets()

        addressItems = wallets.compactMap { wallet in
            if let adapter = interactor.adapter(forWallet: wallet) {
                return AddressItem(coin: wallet.coin,
                                   addressType: (wallet.coinSettings[.derivation] as? MnemonicDerivation)?.addressType,
                                   address: adapter.receiveAddress)
            }
            return nil
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

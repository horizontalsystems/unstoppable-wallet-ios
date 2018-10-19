import UIKit

class DepositInteractor {
    weak var delegate: IDepositInteractorDelegate?

    private let wallets: [Wallet]

    init(wallets: [Wallet]) {
        self.wallets = wallets
    }
}

extension DepositInteractor: IDepositInteractor {

    func getAddressItems() {
        let items = wallets.map {
            AddressItem(address: $0.adapter.receiveAddress, coin: $0.coin)
        }
        delegate?.didGetAddressItems(items: items)
    }

    func onCopy(index: Int) {
        let address = wallets[index].adapter.receiveAddress
        UIPasteboard.general.setValue(address, forPasteboardType: "public.plain-text")
        delegate?.showCopied()
    }

    func onShare(index: Int) {
        let address = wallets[index].adapter.receiveAddress
        delegate?.share(address: address)
    }

}

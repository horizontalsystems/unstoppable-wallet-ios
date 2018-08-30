import UIKit

class DepositInteractor {

    weak var delegate: IDepositInteractorDelegate?

    private let adapters: [IAdapter]

    init(adapters: [IAdapter]) {
        self.adapters = adapters
    }

}

extension DepositInteractor: IDepositInteractor {

    func getAddressItems() {
        let wallets = adapters.map {
            AddressItem(adapterId: $0.id, address: $0.receiveAddress, title: $0.coin.name)
        }
        delegate?.didGetAddressItems(items: wallets)
    }

    func onCopy(index: Int) {
        let address = adapters[index].receiveAddress
        UIPasteboard.general.setValue(address, forPasteboardType: "public.plain-text")
        delegate?.showCopied()
    }

    func onShare(index: Int) {
        let address = adapters[index].receiveAddress
        delegate?.share(address: address)
    }

}

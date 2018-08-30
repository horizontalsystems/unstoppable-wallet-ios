import Foundation

protocol IDepositView: class {
    func onCopy(index: Int)
    func onShare(index: Int)
}

protocol IDepositViewDelegate {
    func viewDidLoad()
    func refresh()
    func onCopy(index: Int)
    func onShare(index: Int)
}

protocol IDepositInteractor {
    func getAddressItems()
    func onCopy(index: Int)
    func onShare(index: Int)
}

protocol IDepositInteractorDelegate: class {
    func didGetAddressItems(items: [AddressItem])
    func showCopied()
    func share(address: String)
}

protocol IDepositRouter {
    func showView(with addresses: [AddressItem])
    func share(address: String)
}

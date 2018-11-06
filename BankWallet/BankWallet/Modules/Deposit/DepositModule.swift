import Foundation

protocol IDepositView: class {
    func showCopied()
}

protocol IDepositViewDelegate {
    func addressItems(forCoin coin: Coin?) -> [AddressItem]
    func onCopy(addressItem: AddressItem)
}

protocol IDepositInteractor {
    func wallets(forCoin coin: Coin?) -> [Wallet]
    func copy(address: String)
}

protocol IDepositInteractorDelegate: class {
}

protocol IDepositRouter {
}

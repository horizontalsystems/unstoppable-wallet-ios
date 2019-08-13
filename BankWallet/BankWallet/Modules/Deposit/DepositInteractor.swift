import UIKit

class DepositInteractor {
    weak var delegate: IDepositInteractorDelegate?

    private let walletManager: IWalletManager
    private let adapterManager: IAdapterManager
    private let pasteboardManager: IPasteboardManager

    init(walletManager: IWalletManager, adapterManager: IAdapterManager, pasteboardManager: IPasteboardManager) {
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.pasteboardManager = pasteboardManager
    }
}

extension DepositInteractor: IDepositInteractor {

    func wallets() -> [Wallet] {
        return walletManager.wallets
    }

    func adapter(forWallet wallet: Wallet) -> IAdapter? {
        return adapterManager.adapter(for: wallet)
    }

    func copy(address: String) {
        pasteboardManager.set(value: address)
    }

}

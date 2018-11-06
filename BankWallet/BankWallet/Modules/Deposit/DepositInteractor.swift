import UIKit

class DepositInteractor {
    weak var delegate: IDepositInteractorDelegate?

    private let walletManager: IWalletManager
    private let pasteboardManager: IPasteboardManager

    init(walletManager: IWalletManager, pasteboardManager: IPasteboardManager) {
        self.walletManager = walletManager
        self.pasteboardManager = pasteboardManager
    }
}

extension DepositInteractor: IDepositInteractor {

    func wallets(forCoin coin: Coin?) -> [Wallet] {
        return walletManager.wallets.filter { coin == nil || coin == $0.coin }
    }

    func copy(address: String) {
        pasteboardManager.set(value: address)
    }

}

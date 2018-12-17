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

    func wallets(forCoin coinCode: CoinCode?) -> [Wallet] {
        return walletManager.wallets.filter { coinCode == nil || coinCode == $0.coinCode }
    }

    func copy(address: String) {
        pasteboardManager.set(value: address)
    }

}

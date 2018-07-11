import Foundation
import WalletKit

class GuestInteractor {
    weak var delegate: IGuestInteractorDelegate?

    private let walletManager: WalletManager

    init(walletManager: WalletManager) {
        self.walletManager = walletManager
    }
}

extension GuestInteractor: IGuestInteractor {

    func createWallet() {
        do {
            try walletManager.createWallet()
            delegate?.didCreateWallet()
        } catch {
            delegate?.didFailToCreateWallet(withError: error)
        }
    }

}

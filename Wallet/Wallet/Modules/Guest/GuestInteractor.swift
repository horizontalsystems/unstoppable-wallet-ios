import Foundation
import WalletKit

class GuestInteractor {
    weak var delegate: IGuestInteractorDelegate?

    private let walletManager: WordsManager

    init(walletManager: WordsManager) {
        self.walletManager = walletManager
    }
}

extension GuestInteractor: IGuestInteractor {

    func createWallet() {
        do {
            try walletManager.createWords()
            delegate?.didCreateWallet()
        } catch {
            delegate?.didFailToCreateWallet(withError: error)
        }
    }

}

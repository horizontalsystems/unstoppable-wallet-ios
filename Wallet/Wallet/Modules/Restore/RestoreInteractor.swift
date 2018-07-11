import Foundation
import WalletKit

class RestoreInteractor {
    weak var delegate: IRestoreInteractorDelegate?

    private let walletManager: WalletManager

    init(walletManager: WalletManager) {
        self.walletManager = walletManager
    }
}

extension RestoreInteractor: IRestoreInteractor {

    func restore(withWords words: [String]) {
        do {
            try walletManager.restoreWallet(withWords: words)
            delegate?.didRestore()
        } catch {
            delegate?.didFailToRestore(withError: error)
        }
    }

}

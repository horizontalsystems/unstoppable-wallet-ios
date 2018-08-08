import Foundation
import WalletKit

class RestoreInteractor {
    weak var delegate: IRestoreInteractorDelegate?

    private let walletManager: WordsManager

    init(walletManager: WordsManager) {
        self.walletManager = walletManager
    }
}

extension RestoreInteractor: IRestoreInteractor {

    func restore(withWords words: [String]) {
        do {
            try walletManager.restore(withWords: words)
            delegate?.didRestore()
        } catch {
            delegate?.didFailToRestore(withError: error)
        }
    }

}

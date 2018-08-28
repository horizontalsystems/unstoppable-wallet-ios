import Foundation

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
            if let words = walletManager.words {
                AdapterManager.shared.initAdapters(words: words)
            }
            delegate?.didCreateWallet()
        } catch {
            delegate?.didFailToCreateWallet(withError: error)
        }
    }

}

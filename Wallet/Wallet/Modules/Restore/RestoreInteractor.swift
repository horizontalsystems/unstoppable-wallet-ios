import Foundation

class RestoreInteractor {
    weak var delegate: IRestoreInteractorDelegate?

    private let walletManager: WordsManager

    init(walletManager: WordsManager) {
        self.walletManager = walletManager
    }
}

extension RestoreInteractor: IRestoreInteractor {

    func validate(words: [String]) {
        do {
            try walletManager.validate(words: words)
            delegate?.didValidate()
        } catch {
            delegate?.didFailToValidate(withError: error)
        }
    }

    func restore(withWords words: [String]) {
        do {
            try walletManager.restore(withWords: words)
            AdapterManager.shared.initAdapters(words: words)
            delegate?.didRestore()
        } catch {
            delegate?.didFailToRestore(withError: error)
        }
    }

}

class RestoreInteractor {
    weak var delegate: IRestoreInteractorDelegate?

    private let wordsManager: IWordsManager
    private let walletManager: IWalletManager

    init(wordsManager: IWordsManager, walletManager: IWalletManager) {
        self.wordsManager = wordsManager
        self.walletManager = walletManager
    }
}

extension RestoreInteractor: IRestoreInteractor {

    func validate(words: [String]) {
        do {
            try wordsManager.validate(words: words)
            delegate?.didValidate()
        } catch {
            delegate?.didFailToValidate(withError: error)
        }
    }

    func restore(withWords words: [String]) {
        do {
            try wordsManager.restore(withWords: words)
            walletManager.initWallets()
            delegate?.didRestore()
        } catch {
            delegate?.didFailToRestore(withError: error)
        }
    }

}

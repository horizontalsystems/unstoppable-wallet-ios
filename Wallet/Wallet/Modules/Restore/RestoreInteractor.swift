class RestoreInteractor {
    weak var delegate: IRestoreInteractorDelegate?

    private let wordsManager: IWordsManager

    init(walletManager: IWordsManager) {
        self.wordsManager = walletManager
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
            App.shared.initLoggedInState()
            delegate?.didRestore()
        } catch {
            delegate?.didFailToRestore(withError: error)
        }
    }

}

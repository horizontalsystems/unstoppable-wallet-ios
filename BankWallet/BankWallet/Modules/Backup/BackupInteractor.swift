class BackupInteractor {

    weak var delegate: IBackupInteractorDelegate?

    private var authManager: IAuthManager
    private var wordsManager: IWordsManager
    private let pinManager: IPinManager
    private var randomManager: IRandomManager

    init(authManager: IAuthManager, wordsManager: IWordsManager, pinManager: IPinManager, randomManager: IRandomManager) {
        self.authManager = authManager
        self.wordsManager = wordsManager
        self.pinManager = pinManager
        self.randomManager = randomManager
    }

    private func fetchWords() {
        if let authData = authManager.authData {
            delegate?.didFetch(words: authData.words)
        }
    }

}

extension BackupInteractor: IBackupInteractor {

    func setBackedUp() {
        wordsManager.isBackedUp = true
    }

    func fetchConfirmationIndexes() {
        delegate?.didFetch(confirmationIndexes: randomManager.getRandomIndexes(count: 2))
    }

    func validate(confirmationWords: [Int: String]) {
        guard let authData = authManager.authData else {
            delegate?.didValidateFailure()
            return
        }

        let words = authData.words

        for (index, word) in confirmationWords {
            if words[index - 1] != word.trimmingCharacters(in: .whitespaces) {
                delegate?.didValidateFailure()
                return
            }
        }

        delegate?.didValidateSuccess()
    }

    func lockIfRequired() {
        if pinManager.isPinSet {
            delegate?.showUnlock()
        } else {
            fetchWords()
        }
    }

}

extension BackupInteractor: IUnlockDelegate {

    func onUnlock() {
        fetchWords()
    }

    func onCancelUnlock() {
    }

}

extension BackupInteractor: IAgreementDelegate {

    func onConfirmAgreement() {
        delegate?.onConfirmAgreement()
    }

}

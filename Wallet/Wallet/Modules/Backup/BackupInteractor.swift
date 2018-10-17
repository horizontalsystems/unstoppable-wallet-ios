class BackupInteractor {

    weak var delegate: IBackupInteractorDelegate?

    private var wordsManager: IWordsManager
    private let pinManager: IPinManager
    private var randomManager: IRandomManager

    init(wordsManager: IWordsManager, pinManager: IPinManager, randomManager: IRandomManager) {
        self.wordsManager = wordsManager
        self.pinManager = pinManager
        self.randomManager = randomManager
    }

    private func fetchWords() {
        if let words = wordsManager.words {
            delegate?.didFetch(words: words)
        }
    }

}

extension BackupInteractor: IBackupInteractor {

    func fetchConfirmationIndexes() {
        delegate?.didFetch(confirmationIndexes: randomManager.getRandomIndexes(count: 2))
    }

    func validate(confirmationWords: [Int: String]) {
        guard let words = wordsManager.words else {
            delegate?.didValidateFailure()
            return
        }

        for (index, word) in confirmationWords {
            if words[index - 1] != word.trimmingCharacters(in: .whitespaces) {
                delegate?.didValidateFailure()
                return
            }
        }
        wordsManager.isBackedUp = true
        delegate?.didValidateSuccess()
    }

    func lockIfRequired() {
        if pinManager.isPinned {
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

}

class BackupConfirmationPresenter: IBackupConfirmationPresenter {
    private static let confirmationWordsCount = 2

    weak var view: IBackupConfirmationView?

    private let router: IBackupConfirmationRouter
    private let randomManager: IRandomManager
    private let wordsValidator: WordsValidator

    private let words: [String]

    private(set) var indexes: [Int]

    init(router: IBackupConfirmationRouter, randomManager: IRandomManager, words: [String]) {
        self.router = router
        self.randomManager = randomManager
        self.words = words

        indexes = randomManager.getRandomIndexes(max: words.count, count: BackupConfirmationPresenter.confirmationWordsCount)
        wordsValidator = WordsValidator(words: words)
    }

}

extension BackupConfirmationPresenter: IBackupConfirmationViewDelegate {

    func validateDidClick(confirmationWords: [String]) {
        do {
            try wordsValidator.validate(confirmationIndexes: indexes, words: confirmationWords)
            router.notifyDidValidate()
        } catch {
            view?.showValidation(error: error)
        }
    }

}

class BackupConfirmationPresenter: IBackupConfirmationPresenter {
    private static let confirmationWordsCount = 2

    weak var view: IBackupConfirmationView?

    private let interactor: IBackupConfirmationInteractor
    private let router: IBackupConfirmationRouter
    private let wordsValidator: WordsValidator

    private let words: [String]

    private(set) var indexes: [Int]

    init(interactor: IBackupConfirmationInteractor, router: IBackupConfirmationRouter, words: [String]) {
        self.interactor = interactor
        self.router = router
        self.words = words

        indexes = interactor.fetchConfirmationIndexes(max: words.count, count: BackupConfirmationPresenter.confirmationWordsCount)
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

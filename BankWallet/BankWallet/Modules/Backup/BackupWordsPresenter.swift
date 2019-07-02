class BackupWordsPresenter: IBackupPresenter {
    weak var view: IBackupView?

    private let interactor: IBackupInteractor
    private let router: IBackupRouter
    private let wordsValidator: WordsValidator

    private let words: [String]
    private let confirmationWordsCount: Int

    init(interactor: IBackupInteractor, router: IBackupRouter, words: [String], confirmationWordsCount: Int) {
        self.interactor = interactor
        self.router = router
        self.words = words
        self.confirmationWordsCount = confirmationWordsCount

        wordsValidator = WordsValidator(words: words)
    }

}

extension BackupWordsPresenter: IBackupInteractorDelegate {

    func didUnlock() {
        view?.show(words: words)
    }

}

extension BackupWordsPresenter: IBackupViewDelegate {

    func cancelDidClick() {
        router.close()
    }

    func backupDidTap() {
        router.showUnlock()
    }

    func showConfirmationDidTap() {
        view?.showWordsConfirmation(withIndexes: interactor.fetchConfirmationIndexes(max: words.count, count: confirmationWordsCount))
    }

    func validateDidClick(confirmationWords: [Int: String]) {
        do {
            try wordsValidator.validate(confirmationWords: confirmationWords)
            interactor.setBackedUp()
            router.close()
        } catch {
            view?.showWordsConfirmation(error: error)
        }
    }

}

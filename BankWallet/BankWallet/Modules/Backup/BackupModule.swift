protocol IBackupView: class {
    func show(words: [String])
    func showWordsConfirmation(withIndexes indexes: [Int])
    func showWordsConfirmation(error: Error)
}

protocol IBackupViewDelegate {
    func cancelDidClick()
    func backupDidTap()
    func showConfirmationDidTap()
    func validateDidClick(confirmationWords: [Int: String])
}

protocol IBackupInteractor {
    func setBackedUp()
    func fetchConfirmationIndexes(max: Int, count: Int) -> [Int]
}

protocol IBackupInteractorDelegate: class {
    func didUnlock()
}

protocol IBackupRouter {
    func showUnlock()
    func close()
}

protocol IBackupPresenter: IBackupInteractorDelegate, IBackupViewDelegate {
    var view: IBackupView? { get set }
}

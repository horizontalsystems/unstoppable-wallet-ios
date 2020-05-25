protocol IBackupConfirmationView: class {
    func onBecomeActive()

    func show(error: Error)
}

protocol IBackupConfirmationViewDelegate {
    var predefinedAccountTitle: String { get }
    var indexes: [Int] { get }

    func generateNewIndexes()
    func validateDidClick(confirmationWords: [String])
}

protocol IBackupConfirmationInteractor {
    func fetchConfirmationIndexes(max: Int, count: Int) -> [Int]
    func validate(words: [String], confirmationIndexes: [Int], confirmationWords: [String]) throws
}

protocol IBackupConfirmationInteractorDelegate: class {
    func onBecomeActive()
}

protocol IBackupConfirmationPresenter {
    var view: IBackupConfirmationView? { get set }
}

protocol IBackupConfirmationRouter {
    func notifyDidValidate()
}

protocol IBackupConfirmationDelegate {
    func didValidate()
}

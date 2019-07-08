protocol IBackupConfirmationView: class {
    func showValidation(error: Error)
}

protocol IBackupConfirmationViewDelegate {
    var indexes: [Int] { get }

    func validateDidClick(confirmationWords: [String])
}

protocol IBackupConfirmationInteractor {
    func fetchConfirmationIndexes(max: Int, count: Int) -> [Int]
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

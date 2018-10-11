import Foundation

protocol IBackupView: class {
    func show(words: [String])
    func showConfirmation(withIndexes indexes: [Int])
    func hideWords()
    func hideConfirmation()
    func showConfirmationError()
    func onValidateSuccess()
    func showWarning()
}

protocol IBackupViewDelegate {
    func cancelDidClick()
    func showWordsDidClick()
    func hideWordsDidClick()
    func showConfirmationDidClick()
    func hideConfirmationDidClick()
    func validateDidClick(confirmationWords: [Int: String])
    func onConfirm()
}

protocol IBackupInteractor {
    func fetchConfirmationIndexes()
    func validate(confirmationWords: [Int: String])
    func lockIfRequired()
}

protocol IBackupInteractorDelegate: class {
    func didFetch(words: [String])
    func didFetch(confirmationIndexes indexes: [Int])
    func didValidateSuccess()
    func didValidateFailure()
    func showUnlock()
}

protocol IBackupRouter {
    func navigateToSetPin()
    func close()
    func showUnlock()
}

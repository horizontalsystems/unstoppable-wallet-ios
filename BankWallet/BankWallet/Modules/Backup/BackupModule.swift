import Foundation

protocol IBackupView: class {
    func show(words: [String])
    func showConfirmation(withIndexes indexes: [Int])
    func hideConfirmation()
    func showConfirmationError()
}

protocol IBackupViewDelegate {
    func cancelDidClick()
    func showWordsDidClick()
    func showConfirmationDidClick()
    func hideConfirmationDidClick()
    func validateDidClick(confirmationWords: [Int: String])
}

protocol IBackupInteractor {
    func setBackedUp()
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
    func onConfirmAgreement()
}

protocol IBackupRouter {
    func showAgreement()
    func navigateToSetPin()
    func close()
    func showUnlock()
}

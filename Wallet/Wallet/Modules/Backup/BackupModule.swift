import Foundation

protocol IBackupView: class {
    func show(words: [String])
    func showConfirmation(withIndexes indexes: [Int])
    func hideWords()
    func hideConfirmation()
    func showConfirmationError()
}

protocol IBackupViewDelegate {
    func cancelDidClick()
    func showWordsDidClick()
    func hideWordsDidClick()
    func showConfirmationDidClick()
    func hideConfirmationDidClick()
    func validateDidClick(confirmationWords: [Int: String])
}

protocol IBackupInteractor {
    func fetchWords()
    func fetchConfirmationIndexes()
    func validate(confirmationWords: [Int: String])
}

protocol IBackupInteractorDelegate: class {
    func didFetch(words: [String])
    func didFetch(confirmationIndexes indexes: [Int])
    func didValidateSuccess()
    func didValidateFailure()
}

protocol IBackupRouter {
    func navigateToMain()
    func close()
}

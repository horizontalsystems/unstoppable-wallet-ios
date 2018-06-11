import Foundation

protocol BackupViewDelegate {
    func cancelDidTap()
    func showWordsDidTap()
    func hideWordsDidTap()
    func showConfirmationDidTap()
    func hideConfirmationDidTap()
    func validateDidTap(confirmationWords: [Int: String])
}

protocol BackupViewProtocol: class {
    func show(words: [String])
    func showConfirmation(withIndexes indexes: [Int])
    func hideWords()
    func hideConfirmation()
    func showValidationFailure()
}

protocol BackupPresenterDelegate {
    func fetchWords()
    func fetchConfirmationIndexes()
    func validate(confirmationWords: [Int: String])
}

protocol BackupPresenterProtocol: class {
    func didFetch(words: [String])
    func didFetch(confirmationIndexes indexes: [Int])
    func didValidateSuccess()
    func didValidateFailure()
}

protocol BackupRouterProtocol {
    func close()
}

protocol BackupRandomIndexesProviderProtocol {
    func getRandomIndexes(count: Int) -> [Int]
}

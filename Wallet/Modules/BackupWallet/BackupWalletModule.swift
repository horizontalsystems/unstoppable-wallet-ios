import Foundation

protocol BackupWalletViewDelegate {
    func cancelDidTap()
    func showWordsDidTap()
    func hideWordsDidTap()
    func showConfirmationDidTap()
    func hideConfirmationDidTap()
    func validateDidTap(confirmationWords: [Int: String])
}

protocol BackupWalletViewProtocol: class {
    func show(words: [String])
    func showConfirmation(withIndexes indexes: [Int])
    func hideWords()
    func hideConfirmation()
    func showValidationFailure()
}

protocol BackupWalletPresenterDelegate {
    func fetchWords()
    func fetchConfirmationIndexes()
    func validate(confirmationWords: [Int: String])
}

protocol BackupWalletPresenterProtocol: class {
    func didFetch(words: [String])
    func didFetch(confirmationIndexes indexes: [Int])
    func didValidateSuccess()
    func didValidateFailure()
}

protocol BackupWalletRouterProtocol {
    func close()
}

protocol BackupWalletWordsProviderProtocol {
    func getWords() -> [String]
}

protocol BackupWalletRandomIndexesProviderProtocol {
    func getRandomIndexes(count: Int) -> [Int]
}

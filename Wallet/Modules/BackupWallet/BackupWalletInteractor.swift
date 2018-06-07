import Foundation

class BackupWalletInteractor {

    weak var presenter: BackupWalletPresenterProtocol?
    var wordsProvider: BackupWalletWordsProviderProtocol
    var indexesProvider: BackupWalletRandomIndexesProviderProtocol

    init(wordsProvider: BackupWalletWordsProviderProtocol, indexesProvider: BackupWalletRandomIndexesProviderProtocol) {
        self.wordsProvider = wordsProvider
        self.indexesProvider = indexesProvider
    }

}

extension BackupWalletInteractor: BackupWalletPresenterDelegate {

    func fetchWords() {
        presenter?.didFetch(words: wordsProvider.getWords())
    }

    func fetchConfirmationIndexes() {
        presenter?.didFetch(confirmationIndexes: indexesProvider.getRandomIndexes(count: 2))
    }

    func validate(confirmationWords: [Int: String]) {
        let words = wordsProvider.getWords()

        for (index, word) in confirmationWords {
            if index > words.count || word != words[index - 1] {
                presenter?.didValidateFailure()
                return
            }
        }

        presenter?.didValidateSuccess()
    }

}

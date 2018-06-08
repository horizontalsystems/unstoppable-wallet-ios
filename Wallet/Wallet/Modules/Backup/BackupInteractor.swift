import Foundation

class BackupInteractor {

    weak var presenter: BackupPresenterProtocol?
    var wordsProvider: BackupWordsProviderProtocol
    var indexesProvider: BackupRandomIndexesProviderProtocol

    init(wordsProvider: BackupWordsProviderProtocol, indexesProvider: BackupRandomIndexesProviderProtocol) {
        self.wordsProvider = wordsProvider
        self.indexesProvider = indexesProvider
    }

}

extension BackupInteractor: BackupPresenterDelegate {

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

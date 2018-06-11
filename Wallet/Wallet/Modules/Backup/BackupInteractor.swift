import Foundation

class BackupInteractor {

    weak var presenter: BackupPresenterProtocol?
    var walletDataProvider: WalletDataProviderProtocol
    var indexesProvider: BackupRandomIndexesProviderProtocol

    init(walletDataProvider: WalletDataProviderProtocol, indexesProvider: BackupRandomIndexesProviderProtocol) {
        self.walletDataProvider = walletDataProvider
        self.indexesProvider = indexesProvider
    }

}

extension BackupInteractor: BackupPresenterDelegate {

    func fetchWords() {
        presenter?.didFetch(words: walletDataProvider.walletData.words)
    }

    func fetchConfirmationIndexes() {
        presenter?.didFetch(confirmationIndexes: indexesProvider.getRandomIndexes(count: 2))
    }

    func validate(confirmationWords: [Int: String]) {
        let words = walletDataProvider.walletData.words

        for (index, word) in confirmationWords {
            if index > words.count || word != words[index - 1] {
                presenter?.didValidateFailure()
                return
            }
        }

        presenter?.didValidateSuccess()
    }

}

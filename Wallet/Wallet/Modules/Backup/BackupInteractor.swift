import Foundation

class BackupInteractor {

    weak var delegate: IBackupInteractorDelegate?

    private var walletDataProvider: IWalletDataProvider
    private var indexesProvider: IRandomProvider

    init(walletDataProvider: IWalletDataProvider, indexesProvider: IRandomProvider) {
        self.walletDataProvider = walletDataProvider
        self.indexesProvider = indexesProvider
    }

}

extension BackupInteractor: IBackupInteractor {

    func fetchWords() {
        delegate?.didFetch(words: walletDataProvider.walletData.words)
    }

    func fetchConfirmationIndexes() {
        delegate?.didFetch(confirmationIndexes: indexesProvider.getRandomIndexes(count: 2))
    }

    func validate(confirmationWords: [Int: String]) {
        let words = walletDataProvider.walletData.words

        for (index, word) in confirmationWords {
            if words[index - 1] != word.trimmingCharacters(in: .whitespaces) {
                delegate?.didValidateFailure()
                return
            }
        }

        delegate?.didValidateSuccess()
    }

}

import Foundation
import WalletKit

class BackupInteractor {

    weak var delegate: IBackupInteractorDelegate?

    private let walletManager: WordsManager
    private var indexesProvider: IRandomProvider

    init(walletManager: WordsManager, indexesProvider: IRandomProvider) {
        self.walletManager = walletManager
        self.indexesProvider = indexesProvider
    }

}

extension BackupInteractor: IBackupInteractor {

    func fetchWords() {
        if let words = walletManager.words {
            delegate?.didFetch(words: words)
        }
    }

    func fetchConfirmationIndexes() {
        delegate?.didFetch(confirmationIndexes: indexesProvider.getRandomIndexes(count: 2))
    }

    func validate(confirmationWords: [Int: String]) {
        guard let words = walletManager.words else {
            delegate?.didValidateFailure()
            return
        }

        for (index, word) in confirmationWords {
            if words[index - 1] != word.trimmingCharacters(in: .whitespaces) {
                delegate?.didValidateFailure()
                return
            }
        }

        delegate?.didValidateSuccess()
    }

}

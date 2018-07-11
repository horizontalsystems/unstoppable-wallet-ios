import Foundation
import WalletKit

class BackupInteractor {

    weak var delegate: IBackupInteractorDelegate?

    private let walletManager: WalletManager
    private var indexesProvider: IRandomProvider

    init(walletManager: WalletManager, indexesProvider: IRandomProvider) {
        self.walletManager = walletManager
        self.indexesProvider = indexesProvider
    }

}

extension BackupInteractor: IBackupInteractor {

    func fetchWords() {
        delegate?.didFetch(words: walletManager.words)
    }

    func fetchConfirmationIndexes() {
        delegate?.didFetch(confirmationIndexes: indexesProvider.getRandomIndexes(count: 2))
    }

    func validate(confirmationWords: [Int: String]) {
        let words = walletManager.words

        for (index, word) in confirmationWords {
            if words[index - 1] != word.trimmingCharacters(in: .whitespaces) {
                delegate?.didValidateFailure()
                return
            }
        }

        delegate?.didValidateSuccess()
    }

}

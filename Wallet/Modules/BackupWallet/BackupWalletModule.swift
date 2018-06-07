import Foundation
import BitcoinKit
import Darwin

class BackupWalletModule {

    static var viewController: UIViewController? {
        let router = BackupWalletRouter()
        let interactor = BackupWalletInteractor(wordsProvider: WalletManager(), indexesProvider: RandomProvider())
        let presenter = BackupWalletPresenter(delegate: interactor, router: router)
        let viewController = BackupWalletNavigationController(viewDelegate: presenter)

        interactor.presenter = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}

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

class WalletManager: BackupWalletWordsProviderProtocol {
    func getWords() -> [String] {
        return ["burden", "swap", "fabric", "book", "palm", "main", "salute", "raw", "core", "reflect", "parade", "tone"]
//        return (try? Mnemonic.generate()) ?? []
    }
}

class RandomProvider: BackupWalletRandomIndexesProviderProtocol {
    func getRandomIndexes(count: Int) -> [Int] {
        var indexes = [Int]()

        while indexes.count < count {
            let index = Int(arc4random_uniform(12) + 1)
            if !indexes.contains(index) {
                indexes.append(index)
            }
        }

        return indexes
    }
}

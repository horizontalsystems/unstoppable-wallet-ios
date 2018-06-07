import Foundation

class BackupWalletPresenter {

    let delegate: BackupWalletPresenterDelegate
    let router: BackupWalletRouterProtocol
    weak var view: BackupWalletViewProtocol?

    init(delegate: BackupWalletPresenterDelegate, router: BackupWalletRouterProtocol) {
        self.delegate = delegate
        self.router = router
    }

}

extension BackupWalletPresenter: BackupWalletPresenterProtocol {

    func didFetch(words: [String]) {
        view?.show(words: words)
    }

    func didFetch(confirmationIndexes indexes: [Int]) {
        view?.showConfirmation(withIndexes: indexes)
    }

    func didValidateSuccess() {
        router.close()
    }

    func didValidateFailure() {
        view?.showValidationFailure()
    }

}

extension BackupWalletPresenter: BackupWalletViewDelegate {

    func cancelDidTap() {
        router.close()
    }

    func showWordsDidTap() {
        delegate.fetchWords()
    }

    func hideWordsDidTap() {
        view?.hideWords()
    }

    func showConfirmationDidTap() {
        delegate.fetchConfirmationIndexes()
    }

    func hideConfirmationDidTap() {
        view?.hideConfirmation()
    }

    func validateDidTap(confirmationWords: [Int: String]) {
        delegate.validate(confirmationWords: confirmationWords)
    }

}

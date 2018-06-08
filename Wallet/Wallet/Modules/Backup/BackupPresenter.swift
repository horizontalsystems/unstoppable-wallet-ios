import Foundation

class BackupPresenter {

    let delegate: BackupPresenterDelegate
    let router: BackupRouterProtocol
    weak var view: BackupViewProtocol?

    init(delegate: BackupPresenterDelegate, router: BackupRouterProtocol) {
        self.delegate = delegate
        self.router = router
    }

}

extension BackupPresenter: BackupPresenterProtocol {

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

extension BackupPresenter: BackupViewDelegate {

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

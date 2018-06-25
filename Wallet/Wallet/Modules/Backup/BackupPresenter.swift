import Foundation

class BackupPresenter {
    enum DismissMode {
        case toMain
        case dismissSelf
    }

    private let interactor: IBackupInteractor
    private let router: IBackupRouter
    weak var view: IBackupView?

    private let dismissMode: DismissMode

    init(interactor: IBackupInteractor, router: IBackupRouter, dismissMode: DismissMode) {
        self.interactor = interactor
        self.router = router
        self.dismissMode = dismissMode
    }

    private func dismiss() {
        switch dismissMode {
        case .toMain:
            router.navigateToMain()
        case .dismissSelf:
            router.close()
        }
    }

}

extension BackupPresenter: IBackupInteractorDelegate {

    func didFetch(words: [String]) {
        view?.show(words: words)
    }

    func didFetch(confirmationIndexes indexes: [Int]) {
        view?.showConfirmation(withIndexes: indexes)
    }

    func didValidateSuccess() {
        dismiss()
    }

    func didValidateFailure() {
        view?.showConfirmationError()
    }

}

extension BackupPresenter: IBackupViewDelegate {

    func cancelDidClick() {
        dismiss()
    }

    func showWordsDidClick() {
        interactor.fetchWords()
    }

    func hideWordsDidClick() {
        view?.hideWords()
    }

    func showConfirmationDidClick() {
        interactor.fetchConfirmationIndexes()
    }

    func validateDidClick(confirmationWords: [Int: String]) {
        interactor.validate(confirmationWords: confirmationWords)
    }

}

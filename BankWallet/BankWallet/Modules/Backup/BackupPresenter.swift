import Foundation

class BackupPresenter {
    enum DismissMode {
        case toSetPin
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
        case .toSetPin:
            router.navigateToSetPin()
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
        view?.onValidateSuccess()
    }

    func didValidateFailure() {
        view?.showConfirmationError()
    }

    func showUnlock() {
        router.showUnlock()
    }

}

extension BackupPresenter: IBackupViewDelegate {

    func cancelDidClick() {
        view?.showWarning()
    }

    func showWordsDidClick() {
        interactor.lockIfRequired()
    }

    func hideWordsDidClick() {
        view?.hideWords()
    }

    func showConfirmationDidClick() {
        interactor.fetchConfirmationIndexes()
    }

    func hideConfirmationDidClick() {
        view?.hideConfirmation()
    }

    func validateDidClick(confirmationWords: [Int: String]) {
        interactor.validate(confirmationWords: confirmationWords)
    }

    func onConfirm() {
        dismiss()
    }

}

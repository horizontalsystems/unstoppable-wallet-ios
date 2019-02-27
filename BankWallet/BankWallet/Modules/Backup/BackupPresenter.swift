import Foundation

class BackupPresenter {
    enum Mode {
        case initial
        case regular
    }

    private let interactor: IBackupInteractor
    private let router: IBackupRouter
    weak var view: IBackupView?

    private let mode: Mode
    private var validated = false

    init(interactor: IBackupInteractor, router: IBackupRouter, mode: Mode) {
        self.interactor = interactor
        self.router = router
        self.mode = mode
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
        switch mode {
        case .initial:
            validated = true
            router.showAgreement()
        case .regular:
            interactor.setBackedUp()
            router.close()
        }
    }

    func didValidateFailure() {
        view?.showConfirmationError()
    }

    func showUnlock() {
        router.showUnlock()
    }

    func onConfirmAgreement() {
        if validated {
            interactor.setBackedUp()
        }

        router.navigateToSetPin()
    }

}

extension BackupPresenter: IBackupViewDelegate {

    func cancelDidClick() {
        switch mode {
        case .initial:
            router.showAgreement()
        case .regular:
            router.close()
        }
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

}

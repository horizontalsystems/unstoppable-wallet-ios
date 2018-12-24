import Foundation

class RestorePresenter {

    private let interactor: IRestoreInteractor
    private let router: IRestoreRouter
    weak var view: IRestoreView?

    init(interactor: IRestoreInteractor, router: IRestoreRouter) {
        self.interactor = interactor
        self.router = router
    }

}

extension RestorePresenter: IRestoreInteractorDelegate {

    func didRestore() {
        router.navigateToSetPin()
    }

    func didFailToRestore(withError error: Error) {
        view?.showInvalidWordsError()
    }

    func didValidate() {
        view?.showConfirmAlert()
    }

    func didFailToValidate(withError error: Error) {
        view?.showInvalidWordsError()
    }

}

extension RestorePresenter: IRestoreViewDelegate {

    func viewDidLoad() {
        view?.set(defaultWords: interactor.defaultWords)
    }

    func restoreDidClick(withWords words: [String]) {
        interactor.validate(words: words)
    }

    func cancelDidClick() {
        router.close()
    }

    func didConfirm(words: [String]) {
        interactor.restore(withWords: words)
    }

}

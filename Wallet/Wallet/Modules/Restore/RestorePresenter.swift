import Foundation

class RestorePresenter {

    let delegate: RestorePresenterDelegate
    let router: RestoreRouterProtocol
    weak var view: RestoreViewProtocol?

    init(delegate: RestorePresenterDelegate, router: RestoreRouterProtocol) {
        self.delegate = delegate
        self.router = router
    }

}

extension RestorePresenter: RestorePresenterProtocol {

    func didFailToRestore() {
        view?.showWordsValidationFailure()
    }

    func didRestoreWallet() {
        router.navigateToMain()
    }

}

extension RestorePresenter: RestoreViewDelegate {

    func restoreDidTap(withWords words: [String]) {
        delegate.restoreWallet(withWords: words)
    }

    func cancelDidTap() {
        router.close()
    }

}

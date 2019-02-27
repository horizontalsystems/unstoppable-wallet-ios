class RestorePresenter {
    private let interactor: IRestoreInteractor
    private let router: IRestoreRouter
    weak var view: IRestoreView?

    private var words = [String]()

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

    func didValidate(words: [String]) {
        self.words = words
        router.showAgreement()
    }

    func didFailToValidate(withError error: Error) {
        view?.showInvalidWordsError()
    }

    func didConfirmAgreement() {
        interactor.restore(withWords: words)
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

}

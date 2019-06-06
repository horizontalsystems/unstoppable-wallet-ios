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

    func didValidate(words: [String]) {
        self.words = words
        router.openSyncMode(with: words)
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

}

class RestorePresenter {
    weak var view: IRestoreView?

    private let interactor: IRestoreInteractor
    private let router: IRestoreRouter

    private var words = [String]()

    init(interactor: IRestoreInteractor, router: IRestoreRouter) {
        self.interactor = interactor
        self.router = router
    }

}

extension RestorePresenter: IRestoreInteractorDelegate {
}

extension RestorePresenter: IRestoreViewDelegate {

    func viewDidLoad() {
        view?.showSelectType(types: PredefinedAccountType.allCases)
    }

    func didSelect(type: PredefinedAccountType) {
        switch type {
        case .mnemonic:
            view?.showWords(defaultWords: interactor.defaultWords)
        case .eos: ()
        case .binance: ()
        }
    }

    func didTapRestore(words: [String]) {
        do {
            try interactor.validate(words: words)
            self.words = words

            view?.showSyncMode()
        } catch {
            view?.show(error: error)
        }
    }

    func didSelectSyncMode(isFast: Bool) {
        print("RESTORE: \(words) \(isFast)")
    }

    func didTapCancel() {
        router.close()
    }

}

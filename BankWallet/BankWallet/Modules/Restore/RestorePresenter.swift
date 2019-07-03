class RestorePresenter {
    weak var view: IRestoreView?

    private let interactor: IRestoreInteractor
    private let router: IRestoreRouter

    private var accountType: AccountType?

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

    func didTapRestore(accountType: AccountType) {
        do {
            if case let .mnemonic(words, _, _) = accountType {
                try interactor.validate(words: words)
            }

            self.accountType = accountType

            view?.showSyncMode()
        } catch {
            view?.show(error: error)
        }
    }

    func didSelectSyncMode(isFast: Bool) {
        guard let accountType = accountType else {
            return
        }

        let syncMode: SyncMode = isFast ? .fast : .slow
        interactor.save(accountType: accountType, syncMode: syncMode)

        router.close()
    }

    func didTapCancel() {
        router.close()
    }

}

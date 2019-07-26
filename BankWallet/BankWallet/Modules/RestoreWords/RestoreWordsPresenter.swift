class RestoreWordsPresenter {
    weak var view: IRestoreWordsView?

    private let mode: RestoreRouter.PresentationMode
    private let router: IRestoreWordsRouter
    private let defaultAccountType: DefaultAccountType
    private var wordsManager: IWordsManager
    private let appConfigProvider: IAppConfigProvider

    private var words: [String]?

    init(mode: RestoreRouter.PresentationMode, router: IRestoreWordsRouter, defaultAccountType: DefaultAccountType, wordsManager: IWordsManager, appConfigProvider: IAppConfigProvider) {
        self.mode = mode
        self.router = router
        self.defaultAccountType = defaultAccountType
        self.wordsManager = wordsManager
        self.appConfigProvider = appConfigProvider
    }

}

extension RestoreWordsPresenter: IRestoreWordsViewDelegate {

    var wordsCount: Int {
        if case let .mnemonic(count) = defaultAccountType {
            return count
        }
        return 12
    }

    func viewDidLoad() {
        if mode == .presented {
            view?.showCancelButton()
        }

        view?.show(defaultWords: appConfigProvider.defaultWords)
    }

    func didTapRestore(words: [String]) {
        do {
            try wordsManager.validate(words: words)
            self.words = words
            router.showSyncMode(delegate: self)
        } catch {
            view?.show(error: error)
        }
    }

    func didTapCancel() {
        router.dismiss()
    }

}

extension RestoreWordsPresenter: ISyncModeDelegate {

    func onSelectSyncMode(isFast: Bool) {
        guard let words = words else { return }

        let accountType: AccountType = .mnemonic(words: words, derivation: .bip44, salt: nil)
        let syncMode: SyncMode = isFast ? .fast : .slow

        switch mode {
        case .pushed: router.notifyRestored(accountType: accountType, syncMode: syncMode)
        case .presented: router.dismissAndNotify(accountType: accountType, syncMode: syncMode)
        }
    }

}

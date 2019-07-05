class RestoreWordsPresenter {
    weak var view: IRestoreWordsView?

    private let router: IRestoreWordsRouter
    private var wordsManager: IWordsManager
    private let appConfigProvider: IAppConfigProvider

    private var words: [String]?

    init(router: IRestoreWordsRouter, wordsManager: IWordsManager, appConfigProvider: IAppConfigProvider) {
        self.router = router
        self.wordsManager = wordsManager
        self.appConfigProvider = appConfigProvider
    }

}

extension RestoreWordsPresenter: IRestoreWordsViewDelegate {

    func viewDidLoad() {
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

}

extension RestoreWordsPresenter: ISyncModeDelegate {

    func onSelectSyncMode(isFast: Bool) {
        guard let words = words else { return }

        let accountType: AccountType = .mnemonic(words: words, derivation: .bip44, salt: nil)
        let syncMode: SyncMode = isFast ? .fast : .slow

        router.notifyRestored(accountType: accountType, syncMode: syncMode)
    }

}

class RestoreWordsPresenter {
    weak var view: IRestoreWordsView?

    private let mode: RestoreRouter.PresentationMode
    private let router: IRestoreWordsRouter
    private var wordsManager: IWordsManager
    private let appConfigProvider: IAppConfigProvider

    private var words: [String]?
    var wordsCount: Int
    private let showSyncMode: Bool

    init(mode: RestoreRouter.PresentationMode, router: IRestoreWordsRouter, wordsCount: Int, showSyncMode: Bool, wordsManager: IWordsManager, appConfigProvider: IAppConfigProvider) {
        self.mode = mode
        self.router = router
        self.wordsCount = wordsCount
        self.showSyncMode = showSyncMode
        self.wordsManager = wordsManager
        self.appConfigProvider = appConfigProvider
    }

    private func notify(words: [String], syncMode: SyncMode?) {
        let accountType: AccountType = .mnemonic(words: words, derivation: .bip44, salt: nil)

        switch mode {
        case .pushed: router.notifyRestored(accountType: accountType, syncMode: syncMode)
        case .presented: router.dismissAndNotify(accountType: accountType, syncMode: syncMode)
        }
    }
}

extension RestoreWordsPresenter: IRestoreWordsViewDelegate {

    func viewDidLoad() {
        if mode == .presented {
            view?.showCancelButton()
        }

        if showSyncMode {
            view?.showNextButton()
        } else {
            view?.showRestoreButton()
        }

        view?.show(defaultWords: appConfigProvider.defaultWords(count: wordsCount))
    }

    func didTapRestore(words: [String]) {
        do {
            try wordsManager.validate(words: words)

            if showSyncMode {
                self.words = words
                router.showSyncMode(delegate: self)
            } else {
                notify(words: words, syncMode: nil)
            }
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
        notify(words: words, syncMode: isFast ? .fast : .slow)
    }

}

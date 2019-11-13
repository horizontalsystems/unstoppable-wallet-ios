class RestoreWordsPresenter {
    weak var view: IRestoreWordsView?

    private let mode: RestoreRouter.PresentationMode
    private let router: IRestoreWordsRouter
    private var wordsManager: IWordsManager
    private let appConfigProvider: IAppConfigProvider

    private var words: [String]?
    let wordsCount: Int
    private let showRestoreOptions: Bool

    init(mode: RestoreRouter.PresentationMode, router: IRestoreWordsRouter, wordsCount: Int, showRestoreOptions: Bool, wordsManager: IWordsManager, appConfigProvider: IAppConfigProvider) {
        self.mode = mode
        self.router = router
        self.wordsCount = wordsCount
        self.showRestoreOptions = showRestoreOptions
        self.wordsManager = wordsManager
        self.appConfigProvider = appConfigProvider
    }

    private func notify(words: [String], syncMode: SyncMode?, derivation: MnemonicDerivation) {
        let accountType: AccountType = .mnemonic(words: words, derivation: derivation, salt: nil)

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

        if showRestoreOptions {
            view?.showNextButton()
        } else {
            view?.showRestoreButton()
        }

        view?.show(defaultWords: appConfigProvider.defaultWords(count: wordsCount))
    }

    func didTapRestore(words: [String]) {
        do {
            try wordsManager.validate(words: words, requiredWordsCount: wordsCount)

            if showRestoreOptions {
                self.words = words
                router.showRestoreOptions(delegate: self)
            } else {
                notify(words: words, syncMode: nil, derivation: .bip44)
            }
        } catch {
            view?.show(error: error)
        }
    }

    func didTapCancel() {
        router.dismiss()
    }

}

extension RestoreWordsPresenter: IRestoreOptionsDelegate {

    func onSelectRestoreOptions(syncMode: SyncMode, derivation: MnemonicDerivation) {
        guard let words = words else { return }
        notify(words: words, syncMode: syncMode, derivation: derivation)
    }

}

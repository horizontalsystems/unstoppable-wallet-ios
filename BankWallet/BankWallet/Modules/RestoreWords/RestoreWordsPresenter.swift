class RestoreWordsPresenter {
    weak var view: IRestoreWordsView?

    private let presentationMode: RestoreRouter.PresentationMode
    private let proceedMode: RestoreRouter.ProceedMode
    private let router: IRestoreWordsRouter
    private var wordsManager: IWordsManager
    private let appConfigProvider: IAppConfigProvider

    let wordsCount: Int

    init(presentationMode: RestoreRouter.PresentationMode, proceedMode: RestoreRouter.ProceedMode, router: IRestoreWordsRouter, wordsCount: Int, wordsManager: IWordsManager, appConfigProvider: IAppConfigProvider) {
        self.presentationMode = presentationMode
        self.proceedMode = proceedMode
        self.router = router
        self.wordsCount = wordsCount
        self.wordsManager = wordsManager
        self.appConfigProvider = appConfigProvider
    }

    private func notify(words: [String]) {
        let accountType: AccountType = .mnemonic(words: words, salt: nil)

        router.notifyChecked(accountType: accountType)
    }
}

extension RestoreWordsPresenter: IRestoreWordsViewDelegate {

    func viewDidLoad() {
        if presentationMode == .presented {
            view?.showCancelButton()
        }
        if proceedMode == .next {
            view?.showNextButton()
        } else {
            view?.showRestoreButton()
        }

        view?.show(defaultWords: appConfigProvider.defaultWords(count: wordsCount))
    }

    func didTapRestore(words: [String]) {
        do {
            try wordsManager.validate(words: words, requiredWordsCount: wordsCount)
            notify(words: words)
        } catch {
            view?.show(error: error)
        }
    }

    func didTapCancel() {
        router.dismiss()
    }

}

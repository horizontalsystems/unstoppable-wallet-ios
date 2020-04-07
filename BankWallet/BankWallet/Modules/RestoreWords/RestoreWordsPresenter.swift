import ThemeKit

class RestoreWordsPresenter {
    weak var view: IRestoreWordsView?

    private let handler: IRestoreAccountTypeHandler
    private var wordsManager: IWordsManager
    private let appConfigProvider: IAppConfigProvider

    let wordsCount: Int

    init(handler: IRestoreAccountTypeHandler, wordsCount: Int, wordsManager: IWordsManager, appConfigProvider: IAppConfigProvider) {
        self.handler = handler
        self.wordsCount = wordsCount
        self.wordsManager = wordsManager
        self.appConfigProvider = appConfigProvider
    }

    private func handle(words: [String]) {
        let accountType: AccountType = .mnemonic(words: words, salt: nil)
        handler.handle(accountType: accountType)
    }
}

extension RestoreWordsPresenter: IRestoreWordsViewDelegate {

    func viewDidLoad() {
        if handler.selectCoins {
            view?.showNextButton()
        } else {
            view?.showRestoreButton()
        }

        view?.show(defaultWords: appConfigProvider.defaultWords(count: wordsCount))
    }

    func didTapRestore(words: [String]) {
        do {
            try wordsManager.validate(words: words, requiredWordsCount: wordsCount)
            handle(words: words)
        } catch {
            view?.show(error: error)
        }
    }

    func didTapCancel() {
        handler.handleCancel()
    }

}

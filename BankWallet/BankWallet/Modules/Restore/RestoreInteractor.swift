class RestoreInteractor {
    weak var delegate: IRestoreInteractorDelegate?

    private var wordsManager: IWordsManager
    private let appConfigProvider: IAppConfigProvider

    init(wordsManager: IWordsManager, appConfigProvider: IAppConfigProvider) {
        self.wordsManager = wordsManager
        self.appConfigProvider = appConfigProvider
    }

}

extension RestoreInteractor: IRestoreInteractor {

    var defaultWords: [String] {
        return appConfigProvider.defaultWords
    }

    func validate(words: [String]) throws {
        try wordsManager.validate(words: words)
    }

}

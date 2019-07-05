class RestoreWordsInteractor {
    weak var delegate: IRestoreWordsInteractorDelegate?

    private var wordsManager: IWordsManager
    private let appConfigProvider: IAppConfigProvider

    init(wordsManager: IWordsManager, appConfigProvider: IAppConfigProvider) {
        self.wordsManager = wordsManager
        self.appConfigProvider = appConfigProvider
    }

}

extension RestoreWordsInteractor: IRestoreWordsInteractor {

    var defaultWords: [String] {
        return appConfigProvider.defaultWords
    }

    func validate(words: [String]) throws {
        try wordsManager.validate(words: words)
    }

}

extension RestoreWordsInteractor: ISyncModeDelegate {

    func onSelectSyncMode(isFast: Bool) {
        delegate?.didSelectSyncMode(isFast: isFast)
    }

}

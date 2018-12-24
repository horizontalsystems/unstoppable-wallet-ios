class RestoreInteractor {
    weak var delegate: IRestoreInteractorDelegate?

    private let wordsManager: IWordsManager
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

    func validate(words: [String]) {
        do {
            try wordsManager.validate(words: words)
            delegate?.didValidate()
        } catch {
            delegate?.didFailToValidate(withError: error)
        }
    }

    func restore(withWords words: [String]) {
        do {
            try wordsManager.restore(withWords: words)
            delegate?.didRestore()
        } catch {
            delegate?.didFailToRestore(withError: error)
        }
    }

}

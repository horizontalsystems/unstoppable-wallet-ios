class RestoreWordsService {
    let wordCount: Int
    private var wordsManager: IWordsManager
    private let appConfigProvider: IAppConfigProvider

    init(wordCount: Int, wordsManager: IWordsManager, appConfigProvider: IAppConfigProvider) {
        self.wordCount = wordCount
        self.wordsManager = wordsManager
        self.appConfigProvider = appConfigProvider
    }

    var defaultWords: [String] {
        appConfigProvider.defaultWords(count: wordCount)
    }

    func accountType(words: [String]) throws -> AccountType {
        try wordsManager.validate(words: words, requiredWordsCount: wordCount)
        return .mnemonic(words: words, salt: nil)
    }

}

class RestoreWordsService {
    private let restoreAccountType: RestoreWordsModule.RestoreAccountType
    private let wordsManager: IWordsManager
    private let appConfigProvider: IAppConfigProvider

    init(restoreAccountType: RestoreWordsModule.RestoreAccountType, wordsManager: IWordsManager, appConfigProvider: IAppConfigProvider) {
        self.restoreAccountType = restoreAccountType
        self.wordsManager = wordsManager
        self.appConfigProvider = appConfigProvider
    }

    var wordCount: Int {
        switch restoreAccountType {
        case .mnemonic(let wordsCount):
            return wordsCount
        case .zCash:
            return 24
        }
    }

    var defaultWords: [String] {
        appConfigProvider.defaultWords(count: wordCount)
    }

    func accountType(words: [String]) throws -> AccountType {
        try wordsManager.validate(words: words, requiredWordsCount: wordCount)

        switch restoreAccountType {
        case .mnemonic:
            return .mnemonic(words: words, salt: nil)
        case .zCash:
            return .zCash(words: words)
        }
    }

}

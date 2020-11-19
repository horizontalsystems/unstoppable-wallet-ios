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
        case .zcash:
            return 24
        }
    }

    var birthdayHeightEnabled: Bool {
        switch restoreAccountType {
        case .mnemonic: return false
        case .zcash: return true
        }
    }

    var accountTitle: String {
        switch restoreAccountType {
        case .mnemonic(let wordsCount): return wordsCount == 24 ? PredefinedAccountType.binance.title : PredefinedAccountType.standard.title
        case .zcash: return PredefinedAccountType.zcash.title
        }
    }

    var defaultWords: [String] {
        appConfigProvider.defaultWords(count: wordCount)
    }

    func accountType(words: [String], birthdayHeight: Int?) throws -> AccountType {
        try wordsManager.validate(words: words, requiredWordsCount: wordCount)

        switch restoreAccountType {
        case .mnemonic:
            return .mnemonic(words: words, salt: nil)
        case .zcash:
            return .zcash(words: words, birthdayHeight: birthdayHeight)
        }
    }

}

import RxSwift
import RxRelay
import MarketKit
import HdWalletKit
import LanguageKit

class CreateAccountService {
    private let accountFactory: AccountFactory
    private let predefinedBlockchainService: PredefinedBlockchainService
    private let languageManager: LanguageManager
    private let accountManager: AccountManager
    private let walletManager: WalletManager
    private let marketKit: Kit

    private let wordCountRelay = PublishRelay<Mnemonic.WordCount>()
    private(set) var wordCount: Mnemonic.WordCount = .twelve {
        didSet {
            wordCountRelay.accept(wordCount)
        }
    }

    private let wordListRelay = PublishRelay<Mnemonic.Language>()
    private(set) var wordList: Mnemonic.Language = .english {
        didSet {
            wordListRelay.accept(wordList)
        }
    }

    private let passphraseEnabledRelay = BehaviorRelay<Bool>(value: false)

    var passphrase: String = ""
    var passphraseConfirmation: String = ""

    init(accountFactory: AccountFactory, predefinedBlockchainService: PredefinedBlockchainService, languageManager: LanguageManager, accountManager: AccountManager, walletManager: WalletManager, marketKit: Kit) {
        self.accountFactory = accountFactory
        self.predefinedBlockchainService = predefinedBlockchainService
        self.languageManager = languageManager
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.marketKit = marketKit
    }

    private func activateDefaultWallets(account: Account) {
        let defaultBlockchainTypes: [BlockchainType] = [.bitcoin, .ethereum, .binanceSmartChain, .avalanche]

        var wallets = [Wallet]()

        for blockchainType in defaultBlockchainTypes {
            guard let token = try? marketKit.token(query: TokenQuery(blockchainType: blockchainType, tokenType: .native)) else {
                continue
            }

            predefinedBlockchainService.prepareNew(account: account, blockchainType: blockchainType)

            let defaultSettingsArray = blockchainType.defaultSettingsArray(accountType: account.type)

            if defaultSettingsArray.isEmpty {
                wallets.append(Wallet(token: token, account: account))
            } else {
                for coinSettings in defaultSettingsArray {
                    let configuredToken = ConfiguredToken(token: token, coinSettings: coinSettings)
                    wallets.append(Wallet(configuredToken: configuredToken, account: account))
                }
            }
        }

        walletManager.save(wallets: wallets)
    }

    private func language(wordList: Mnemonic.Language) -> String {
        switch wordList {
        case .english: return "en"
        case .japanese: return "ja"
        case .korean: return "ko"
        case .spanish: return "es"
        case .simplifiedChinese: return "zh-Hans"
        case .traditionalChinese: return "zh-Hant"
        case .french: return "fr"
        case .italian: return "it"
        case .czech: return "cs"
        case .portuguese: return "pt"
        }
    }

}

extension CreateAccountService {

    var wordCountObservable: Observable<Mnemonic.WordCount> {
        wordCountRelay.asObservable()
    }

    var wordListObservable: Observable<Mnemonic.Language> {
        wordListRelay.asObservable()
    }

    var passphraseEnabled: Bool {
        passphraseEnabledRelay.value
    }

    var passphraseEnabledObservable: Observable<Bool> {
        passphraseEnabledRelay.asObservable()
    }

    func displayName(wordList: Mnemonic.Language) -> String {
        languageManager.displayName(language: language(wordList: wordList)) ?? "\(wordList)"
    }

    func set(wordCount: Mnemonic.WordCount) {
        self.wordCount = wordCount
    }

    func set(wordList: Mnemonic.Language) {
        self.wordList = wordList
    }

    func set(passphraseEnabled: Bool) {
        passphraseEnabledRelay.accept(passphraseEnabled)
    }

    func createAccount() throws {
        if passphraseEnabled {
            guard !passphrase.isEmpty else {
                throw CreateError.emptyPassphrase
            }

            guard passphrase == passphraseConfirmation else {
                throw CreateError.invalidConfirmation
            }
        }

        let words = try Mnemonic.generate(wordCount: wordCount, language: wordList)
        let accountType: AccountType = .mnemonic(words: words, salt: passphrase)
        let account = accountFactory.account(type: accountType, origin: .created)

        accountManager.save(account: account)
        activateDefaultWallets(account: account)

        accountManager.set(lastCreatedAccount: account)
    }

}

extension CreateAccountService {

    enum CreateError: Error {
        case emptyPassphrase
        case invalidConfirmation
    }

}

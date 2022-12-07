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

}

extension CreateAccountService {

    var wordCountObservable: Observable<Mnemonic.WordCount> {
        wordCountRelay.asObservable()
    }

    var passphraseEnabled: Bool {
        passphraseEnabledRelay.value
    }

    var passphraseEnabledObservable: Observable<Bool> {
        passphraseEnabledRelay.asObservable()
    }

    func set(wordCount: Mnemonic.WordCount) {
        self.wordCount = wordCount
    }

    func set(passphraseEnabled: Bool) {
        passphraseEnabledRelay.accept(passphraseEnabled)
    }

    func validate(text: String?) -> Bool {
        PassphraseValidator.validate(text: text)
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

        let words = try Mnemonic.generate(wordCount: wordCount, language: .english)
        let accountType: AccountType = .mnemonic(words: words, salt: passphrase, bip39Compliant: true)
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

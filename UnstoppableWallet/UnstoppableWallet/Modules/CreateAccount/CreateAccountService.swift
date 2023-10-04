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

    var name: String = ""
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

    private func activateDefaultWallets(account: Account) throws {
        let tokenQueries = [
            TokenQuery(blockchainType: .bitcoin, tokenType: .derived(derivation: .bip84)), //todo: make derivation supports accountType
            TokenQuery(blockchainType: .ethereum, tokenType: .native),
            TokenQuery(blockchainType: .binanceSmartChain, tokenType: .native),
            TokenQuery(blockchainType: .ethereum, tokenType: .eip20(address: "0xdac17f958d2ee523a2206206994597c13d831ec7")), // USDT
            TokenQuery(blockchainType: .binanceSmartChain, tokenType: .eip20(address: "0xe9e7cea3dedca5984780bafc599bd69add087d56")) // BUSD
        ]

        var wallets = [Wallet]()

        for token in try marketKit.tokens(queries: tokenQueries) {
            predefinedBlockchainService.prepareNew(account: account, blockchainType: token.blockchainType)
            wallets.append(Wallet(token: token, account: account))
        }

        walletManager.save(wallets: wallets)
    }

}

extension CreateAccountService {

    var wordCountObservable: Observable<Mnemonic.WordCount> {
        wordCountRelay.asObservable()
    }

    var passphraseEnabledObservable: Observable<Bool> {
        passphraseEnabledRelay.asObservable()
    }

    var defaultAccountName: String {
        accountFactory.nextAccountName
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
        if passphraseEnabledRelay.value {
            guard !passphrase.isEmpty else {
                throw CreateError.emptyPassphrase
            }

            guard passphrase == passphraseConfirmation else {
                throw CreateError.invalidConfirmation
            }
        }

        let words = try Mnemonic.generate(wordCount: wordCount, language: .english)
        let accountType: AccountType = .mnemonic(words: words, salt: passphrase, bip39Compliant: true)

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let account = accountFactory.account(
                type: accountType,
                origin: .created,
                backedUp: false,
                fileBackedUp: false,
                name: trimmedName.isEmpty ? defaultAccountName : trimmedName
        )

        accountManager.save(account: account)
        try activateDefaultWallets(account: account)

        accountManager.set(lastCreatedAccount: account)
    }

}

extension CreateAccountService {

    enum CreateError: Error {
        case emptyPassphrase
        case invalidConfirmation
    }

}

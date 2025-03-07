import HdWalletKit
import MarketKit
import RxRelay
import RxSwift

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
            TokenQuery(blockchainType: .bitcoin, tokenType: .derived(derivation: .bip84)), // TODO: make derivation supports accountType
            TokenQuery(blockchainType: .ethereum, tokenType: .native),
            TokenQuery(blockchainType: .binanceSmartChain, tokenType: .native),
            TokenQuery(blockchainType: .tron, tokenType: .native),
            TokenQuery(blockchainType: .polygon, tokenType: .native),
            TokenQuery(blockchainType: .ethereum, tokenType: .eip20(address: "0xdac17f958d2ee523a2206206994597c13d831ec7")), // USDT
            TokenQuery(blockchainType: .binanceSmartChain, tokenType: .eip20(address: "0x55d398326f99059fF775485246999027B3197955")), // USDT
            TokenQuery(blockchainType: .tron, tokenType: .eip20(address: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t")), // USDT
            TokenQuery(blockchainType: .base, tokenType: .eip20(address: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913")), // USDC
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

    func createAccount(advanced: Bool) throws {
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

        stat(page: advanced ? .newWalletAdvanced : .newWallet, event: .createWallet(walletType: accountType.statDescription))
    }
}

extension CreateAccountService {
    enum CreateError: Error {
        case emptyPassphrase
        case invalidConfirmation
    }
}

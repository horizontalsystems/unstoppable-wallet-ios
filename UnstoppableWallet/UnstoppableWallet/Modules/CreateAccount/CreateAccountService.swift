import RxSwift
import RxRelay
import MarketKit
import HdWalletKit

class CreateAccountService {
    private let accountFactory: AccountFactory
    private let predefinedBlockchainService: PredefinedBlockchainService
    private let accountManager: AccountManager
    private let walletManager: WalletManager
    private let passphraseValidator: PassphraseValidator
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

    init(accountFactory: AccountFactory, predefinedBlockchainService: PredefinedBlockchainService, accountManager: AccountManager, walletManager: WalletManager, passphraseValidator: PassphraseValidator, marketKit: Kit) {
        self.accountFactory = accountFactory
        self.predefinedBlockchainService = predefinedBlockchainService
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.passphraseValidator = passphraseValidator
        self.marketKit = marketKit
    }

    private func activateDefaultWallets(account: Account) {
        let defaultBlockchainTypes: [BlockchainType] = [.bitcoin, .ethereum, .binanceSmartChain, .polygon, .avalanche, .zcash]

        var wallets = [Wallet]()

        for blockchainType in defaultBlockchainTypes {
            guard let token = try? marketKit.token(query: TokenQuery(blockchainType: blockchainType, tokenType: .native)) else {
                continue
            }

            predefinedBlockchainService.prepareNew(account: account, blockchainType: blockchainType)

            let defaultSettingsArray = blockchainType.defaultSettingsArray

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
        passphraseValidator.validate(text: text)
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

        let words = try Mnemonic.generate(wordCount: wordCount)
        let accountType: AccountType = .mnemonic(words: words, salt: passphrase)
        let account = accountFactory.account(name: accountFactory.nextAccountName, type: accountType, origin: .created)

        accountManager.save(account: account)
        activateDefaultWallets(account: account)
    }

}

extension CreateAccountService {

    enum CreateError: Error {
        case emptyPassphrase
        case invalidConfirmation
    }

}

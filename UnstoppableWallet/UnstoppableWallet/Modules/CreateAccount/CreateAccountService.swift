import RxSwift
import RxRelay
import MarketKit

class CreateAccountService {
    private let accountFactory: AccountFactory
    private let wordsManager: WordsManager
    private let accountManager: AccountManager
    private let walletManager: WalletManager
    private let passphraseValidator: PassphraseValidator
    private let marketKit: Kit

    private let kindRelay = BehaviorRelay<CreateAccountModule.Kind>(value: .mnemonic12)
    private let passphraseEnabledRelay = BehaviorRelay<Bool>(value: false)

    var passphrase: String = ""
    var passphraseConfirmation: String = ""

    init(accountFactory: AccountFactory, wordsManager: WordsManager, accountManager: AccountManager, walletManager: WalletManager, passphraseValidator: PassphraseValidator, marketKit: Kit) {
        self.accountFactory = accountFactory
        self.wordsManager = wordsManager
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.passphraseValidator = passphraseValidator
        self.marketKit = marketKit
    }

    private func resolveAccountType() throws -> AccountType {
        switch kind {
        case .mnemonic12:
            return try mnemonicAccountType(wordCount: 12)
        case .mnemonic24:
            return try mnemonicAccountType(wordCount: 24)
        }
    }

    private func mnemonicAccountType(wordCount: Int) throws -> AccountType {
        let words = try wordsManager.generateWords(count: wordCount)
        return .mnemonic(words: words, salt: passphrase)
    }

    private func activateDefaultWallets(account: Account) {
        let defaultBlockchainTypes: [BlockchainType] = [.bitcoin, .ethereum, .binanceSmartChain, .polygon, .zcash]

        var wallets = [Wallet]()

        for blockchainType in defaultBlockchainTypes {
            guard let token = try? marketKit.token(query: TokenQuery(blockchainType: blockchainType, tokenType: .native)) else {
                continue
            }

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

    var kind: CreateAccountModule.Kind {
        kindRelay.value
    }

    var kindObservable: Observable<CreateAccountModule.Kind> {
        kindRelay.asObservable()
    }

    var passphraseEnabled: Bool {
        passphraseEnabledRelay.value
    }

    var passphraseEnabledObservable: Observable<Bool> {
        passphraseEnabledRelay.asObservable()
    }

    var allKinds: [CreateAccountModule.Kind] {
        CreateAccountModule.Kind.allCases
    }

    func setKind(index: Int) {
        kindRelay.accept(allKinds[index])
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

        let accountType = try resolveAccountType()
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

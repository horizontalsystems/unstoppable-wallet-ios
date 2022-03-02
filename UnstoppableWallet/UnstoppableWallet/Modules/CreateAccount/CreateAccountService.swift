import RxSwift
import RxRelay
import MarketKit

class CreateAccountService {
    private let accountFactory: AccountFactory
    private let wordsManager: IWordsManager
    private let accountManager: IAccountManager
    private let walletManager: WalletManager
    private let passphraseValidator: PassphraseValidator
    private let marketKit: Kit

    private let kindRelay = BehaviorRelay<CreateAccountModule.Kind>(value: .mnemonic12)
    private let passphraseEnabledRelay = BehaviorRelay<Bool>(value: false)

    var passphrase: String = ""
    var passphraseConfirmation: String = ""

    init(accountFactory: AccountFactory, wordsManager: IWordsManager, accountManager: IAccountManager, walletManager: WalletManager, passphraseValidator: PassphraseValidator, marketKit: Kit) {
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
        let defaultCoinTypes: [CoinType] = [.bitcoin, .ethereum, .binanceSmartChain, .polygon, .zcash]

        var wallets = [Wallet]()

        for coinType in defaultCoinTypes {
            guard let platformCoin = try? marketKit.platformCoin(coinType: coinType) else {
                continue
            }

            let defaultSettingsArray = coinType.defaultSettingsArray

            if defaultSettingsArray.isEmpty {
                wallets.append(Wallet(platformCoin: platformCoin, account: account))
            } else {
                for coinSettings in defaultSettingsArray {
                    let configuredPlatformCoin = ConfiguredPlatformCoin(platformCoin: platformCoin, coinSettings: coinSettings)
                    wallets.append(Wallet(configuredPlatformCoin: configuredPlatformCoin, account: account))
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
        let account = accountFactory.account(type: accountType, origin: .created)

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

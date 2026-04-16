import Combine
import HdWalletKit
import MarketKit

class CreateAccountViewModel: ObservableObject {
    private static let defaultWordCount: Mnemonic.WordCount = .twelve

    private let accountFactory = Core.shared.accountFactory
    private let accountManager = Core.shared.accountManager
    private let walletManager = Core.shared.walletManager
    private let marketKit = Core.shared.marketKit
    private let predefinedBlockchainService = Core.shared.predefinedBlockchainService
    private let passkeyManager = PasskeyManager()

    let walletType: WalletType

    @Published var name: String {
        didSet {
            createEnabled = !resolvedName.isEmpty
        }
    }

    @Published var advanced = false
    @Published var wordCount: Mnemonic.WordCount = CreateAccountViewModel.defaultWordCount

    @Published var passphrase = ""
    @Published var passphraseConfirmation = ""

    @Published var createEnabled = true

    init(walletType: WalletType) {
        self.walletType = walletType
        name = accountFactory.generatedAccountName
    }

    private func activateDefaultWallets(account: Account) throws {
        let tokenQueries = [
            TokenQuery(blockchainType: .bitcoin, tokenType: .derived(derivation: .bip84)), // TODO: make derivation supports accountType
            TokenQuery(blockchainType: .ethereum, tokenType: .native),
            TokenQuery(blockchainType: .monero, tokenType: .native),
            TokenQuery(blockchainType: .tron, tokenType: .native),
            TokenQuery(blockchainType: .binanceSmartChain, tokenType: .native),
            TokenQuery(blockchainType: .ethereum, tokenType: .eip20(address: "0xdac17f958d2ee523a2206206994597c13d831ec7")), // USDT
            TokenQuery(blockchainType: .tron, tokenType: .eip20(address: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t")), // USDT
        ]

        var wallets = [Wallet]()

        for token in try marketKit.tokens(queries: tokenQueries) {
            predefinedBlockchainService.prepareNew(account: account, blockchainType: token.blockchainType)
            wallets.append(Wallet(token: token, account: account))
        }

        walletManager.save(wallets: wallets)
    }

    private var resolvedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func createAccount(words: [String], salt: String, isPasskey: Bool, statPage: StatPage) -> Account {
        let accountType: AccountType = .mnemonic(words: words, salt: salt, bip39Compliant: true)

        let account = accountFactory.account(
            type: accountType,
            origin: .created,
            backedUp: isPasskey,
            fileBackedUp: false,
            name: resolvedName
        )

        accountManager.save(account: account)

        try? activateDefaultWallets(account: account)

        accountManager.set(lastCreatedAccount: account)

        stat(page: statPage, event: .createWallet(walletType: accountType.statDescription))

        return account
    }
}

extension CreateAccountViewModel {
    func refreshName() {
        name = accountFactory.generatedAccountName
    }

    func createAccount() throws -> Account {
        let salt: String
        if advanced, !passphrase.isEmpty || !passphraseConfirmation.isEmpty {
            guard !passphrase.isEmpty else {
                throw CreateError.emptyPassphrase
            }

            guard passphrase == passphraseConfirmation else {
                throw CreateError.invalidConfirmation
            }

            salt = passphrase
        } else {
            salt = ""
        }

        let wordCount = advanced ? wordCount : Self.defaultWordCount
        let words = try Mnemonic.generate(wordCount: wordCount, language: .english)

        return createAccount(words: words, salt: salt, isPasskey: false, statPage: advanced ? .newWalletAdvanced : .newWallet)
    }

    func createPasskeyAccount() async throws -> Account {
        let credentialID = try await passkeyManager.create(name: resolvedName)
        let passkey = try await passkeyManager.loginWith(credentialID: credentialID)

        return createAccount(words: passkey.mnemonic, salt: "", isPasskey: true, statPage: .newWalletPasskey)
    }
}

extension CreateAccountViewModel {
    enum WalletType {
        case regular
        case passkey
    }

    enum CreateError: Error {
        case emptyPassphrase
        case invalidConfirmation
    }
}

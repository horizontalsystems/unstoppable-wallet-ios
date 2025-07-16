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

    let defaultAccountName: String

    @Published var name: String = ""
    @Published var advanced = false
    @Published var wordCount: Mnemonic.WordCount = CreateAccountViewModel.defaultWordCount
    @Published var passphraseEnabled = false

    @Published var passphrase = ""
    @Published var passphraseConfirmation = ""

    init() {
        defaultAccountName = accountFactory.nextAccountName
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

extension CreateAccountViewModel {
    func createAccount() throws -> Account {
        if passphraseEnabled {
            guard !passphrase.isEmpty else {
                throw CreateError.emptyPassphrase
            }

            guard passphrase == passphraseConfirmation else {
                throw CreateError.invalidConfirmation
            }
        }

        let wordCount = advanced ? wordCount : Self.defaultWordCount

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

        try? activateDefaultWallets(account: account)

        accountManager.set(lastCreatedAccount: account)

        stat(page: advanced ? .newWalletAdvanced : .newWallet, event: .createWallet(walletType: accountType.statDescription))

        return account
    }
}

extension CreateAccountViewModel {
    enum CreateError: Error {
        case emptyPassphrase
        case invalidConfirmation
    }
}

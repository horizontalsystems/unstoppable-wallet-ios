import RxSwift
import RxRelay
import CoinKit

class CreateAccountService {
    private let accountFactory: IAccountFactory
    private let wordsManager: IWordsManager
    private let accountManager: IAccountManager
    private let walletManager: IWalletManager
    private let coinKit: CoinKit.Kit

    private let kindRelay = PublishRelay<CreateAccountModule.Kind>()
    private(set) var kind: CreateAccountModule.Kind = .mnemonic12 {
        didSet {
            kindRelay.accept(kind)
        }
    }

    init(accountFactory: IAccountFactory, wordsManager: IWordsManager, accountManager: IAccountManager, walletManager: IWalletManager, coinKit: CoinKit.Kit) {
        self.accountFactory = accountFactory
        self.wordsManager = wordsManager
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.coinKit = coinKit
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
        return .mnemonic(words: words, salt: nil)
    }

    private func activateDefaultWallets(account: Account) {
        let defaultCoinTypes: [CoinType] = [.bitcoin, .ethereum, .binanceSmartChain]

        let wallets: [Wallet] = defaultCoinTypes.compactMap { coinType in
            guard let coin = coinKit.coin(type: coinType) else {
                return nil
            }

            return Wallet(coin: coin, account: account)
        }

        walletManager.save(wallets: wallets)
    }

}

extension CreateAccountService {

    var kindObservable: Observable<CreateAccountModule.Kind> {
        kindRelay.asObservable()
    }

    var allKinds: [CreateAccountModule.Kind] {
        CreateAccountModule.Kind.allCases
    }

    func setKind(index: Int) {
        kind = allKinds[index]
    }

    func createAccount() throws {
        let accountType = try resolveAccountType()
        let account = accountFactory.account(type: accountType, origin: .created, backedUp: false)

        accountManager.save(account: account)
        activateDefaultWallets(account: account)
    }

}

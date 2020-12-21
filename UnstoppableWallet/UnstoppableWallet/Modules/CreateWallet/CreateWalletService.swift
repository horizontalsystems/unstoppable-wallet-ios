import RxSwift
import RxRelay

class CreateWalletService {
    private var predefinedAccountType: PredefinedAccountType?
    private let coinManager: ICoinManager
    private let accountCreator: IAccountCreator
    private let accountManager: IAccountManager
    private let predefinedAccountTypeManager: IPredefinedAccountTypeManager
    private let walletManager: IWalletManager
    private let derivationSettingsManager: IDerivationSettingsManager
    private let bitcoinCashCoinTypeManager: BitcoinCashCoinTypeManager

    private var accounts = [PredefinedAccountType: Account]()
    private var wallets = [Coin: Wallet]()

    private let stateRelay = PublishRelay<State>()
    private let canCreateRelay = BehaviorRelay<Bool>(value: false)

    var state = State.empty {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(predefinedAccountType: PredefinedAccountType?, coinManager: ICoinManager, accountCreator: IAccountCreator, accountManager: IAccountManager, predefinedAccountTypeManager: IPredefinedAccountTypeManager, walletManager: IWalletManager, derivationSettingsManager: IDerivationSettingsManager, bitcoinCashCoinTypeManager: BitcoinCashCoinTypeManager) {
        self.predefinedAccountType = predefinedAccountType
        self.coinManager = coinManager
        self.accountCreator = accountCreator
        self.accountManager = accountManager
        self.predefinedAccountTypeManager = predefinedAccountTypeManager
        self.walletManager = walletManager
        self.derivationSettingsManager = derivationSettingsManager
        self.bitcoinCashCoinTypeManager = bitcoinCashCoinTypeManager

        syncState()
    }

    private func filteredCoins(coins: [Coin]) -> [Coin] {
        guard let predefinedAccountType = predefinedAccountType else {
            return coins
        }

        return coins.filter { $0.type.predefinedAccountType == predefinedAccountType }
    }

    private func item(coin: Coin) -> Item? {
        guard coin.type.predefinedAccountType.createSupported else {
            return nil
        }

        return Item(
                coin: coin,
                enabled: wallets[coin] != nil
        )
    }

    private func syncState() {
        let featuredCoins = filteredCoins(coins: coinManager.featuredCoins)
        let coins = filteredCoins(coins: coinManager.coins).filter { !featuredCoins.contains($0) }

        state = State(
                featuredItems: featuredCoins.compactMap { item(coin: $0) },
                items: coins.compactMap { item(coin: $0) }
        )
    }

    private func syncCanCreate() {
        canCreateRelay.accept(!wallets.isEmpty)
    }

    private func resolveAccount(predefinedAccountType: PredefinedAccountType) throws -> Account {
        if let account = accounts[predefinedAccountType] {
            return account
        }

        let account = try accountCreator.newAccount(predefinedAccountType: predefinedAccountType)
        accounts[predefinedAccountType] = account
        return account
    }

}

extension CreateWalletService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var canCreateObservable: Observable<Bool> {
        canCreateRelay.asObservable()
    }

    func enable(coin: Coin) throws {
        let account = try resolveAccount(predefinedAccountType: coin.type.predefinedAccountType)
        wallets[coin] = Wallet(coin: coin, account: account)
        syncState()
        syncCanCreate()
    }

    func disable(coin: Coin) {
        wallets.removeValue(forKey: coin)
        syncState()
        syncCanCreate()
    }

    func create() throws {
        guard !wallets.isEmpty else {
            throw CreateError.noWallets
        }

        let accounts = Array(Set(wallets.values.map { $0.account }))
        for account in accounts {
            accountManager.save(account: account)
        }


        let creatingStandardAccount = accounts.contains { account in
            predefinedAccountTypeManager.predefinedAccountType(accountType: account.type) == .standard
        }

        if creatingStandardAccount {
            derivationSettingsManager.resetStandardSettings()
            bitcoinCashCoinTypeManager.reset()
        }

        walletManager.save(wallets: Array(wallets.values))
    }

}

extension CreateWalletService {

    struct State {
        let featuredItems: [Item]
        let items: [Item]

        static var empty: State {
            State(featuredItems: [], items: [])
        }
    }

    struct Item {
        let coin: Coin
        var enabled: Bool

        init(coin: Coin, enabled: Bool) {
            self.coin = coin
            self.enabled = enabled
        }
    }

    enum CreateError: Error {
        case noWallets
    }

}

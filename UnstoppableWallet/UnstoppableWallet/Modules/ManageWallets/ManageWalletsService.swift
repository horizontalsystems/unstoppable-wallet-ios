import RxSwift
import RxRelay

class ManageWalletsService {
    private let coinManager: ICoinManager
    private let walletManager: IWalletManager
    private let accountManager: IAccountManager
    private let enableCoinsService: EnableCoinsService
    private let blockchainSettingsService: BlockchainSettingsService
    private let disposeBag = DisposeBag()

    private var wallets = [Coin: Wallet]()

    private let stateRelay = PublishRelay<State>()
    private let enableCoinRelay = PublishRelay<Coin>()
    private let cancelEnableCoinRelay = PublishRelay<Coin>()

    private var coinToEnable: Coin?

    var state = State.empty {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(coinManager: ICoinManager, walletManager: IWalletManager, accountManager: IAccountManager, enableCoinsService: EnableCoinsService, blockchainSettingsService: BlockchainSettingsService) {
        self.coinManager = coinManager
        self.walletManager = walletManager
        self.accountManager = accountManager
        self.enableCoinsService = enableCoinsService
        self.blockchainSettingsService = blockchainSettingsService

        accountManager.accountsObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] _ in
                    self?.syncState()
                    self?.handleAccountsChanged()
                })
                .disposed(by: disposeBag)

        coinManager.coinAddedObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] _ in
                    self?.syncState()
                })
                .disposed(by: disposeBag)

        walletManager.walletsUpdatedObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] wallets in
                    self?.sync(wallets: wallets)
                })
                .disposed(by: disposeBag)

        enableCoinsService.enableCoinsObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] coins in
                    self?.enable(coins: coins)
                })
                .disposed(by: disposeBag)

        blockchainSettingsService.approveEnableCoinObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] coin in
                    self?.handleApproveEnable(coin: coin)
                })
                .disposed(by: disposeBag)

        blockchainSettingsService.rejectEnableCoinObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] coin in
                    self?.cancelEnableCoinRelay.accept(coin)
                })
                .disposed(by: disposeBag)

        sync(wallets: walletManager.wallets)
    }

    private func sync(wallets: [Wallet]) {
        self.wallets = [:]

        for wallet in wallets {
            self.wallets[wallet.coin] = wallet
        }

        syncState()
    }

    private func item(coin: Coin) -> Item {
        let state: ItemState

        if let account = account(coinType: coin.type) {
            state = .hasAccount(account: account, hasWallet: wallets[coin] != nil)
        } else {
            state = .noAccount
        }

        return Item(coin: coin, state: state)
    }

    private func syncState() {
        let featuredCoins = coinManager.featuredCoins
        let coins = coinManager.coins.filter { !featuredCoins.contains($0) }

        state = State(
                featuredItems: featuredCoins.map { item(coin: $0) },
                items: coins.map { item(coin: $0) }
        )
    }

    private func wallet(coin: Coin) -> Wallet? {
        guard let item = state.item(coin: coin), case .hasAccount(let account, _) = item.state else {
            return nil // impossible case
        }

        return Wallet(coin: coin, account: account)
    }

    private func handleApproveEnable(coin: Coin) {
        enable(coins: [coin])

        guard let account = account(coinType: coin.type), account.origin == .restored else {
            return
        }

        enableCoinsService.handle(coinType: coin.type, accountType: account.type)
    }

    private func enable(coins: [Coin]) {
        let nonEnabledCoins = coins.filter { coin in
            !wallets.keys.contains(coin)
        }

        walletManager.save(wallets: nonEnabledCoins.compactMap { wallet(coin: $0) })
    }

    private func handleAccountsChanged() {
        guard let coinToEnable = coinToEnable else {
            return
        }

        enableCoinRelay.accept(coinToEnable)
        enable(coin: coinToEnable)

        self.coinToEnable = nil
    }

}

extension ManageWalletsService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var enableCoinObservable: Observable<Coin> {
        enableCoinRelay.asObservable()
    }

    var cancelEnableCoinObservable: Observable<Coin> {
        cancelEnableCoinRelay.asObservable()
    }

    func account(coinType: CoinType) -> Account? {
        accountManager.account(coinType: coinType)
    }

    func enable(coin: Coin) {
        guard let item = state.item(coin: coin), case .hasAccount(let account, _) = item.state else {
            return // impossible case
        }

        blockchainSettingsService.approveEnable(coin: coin, accountOrigin: account.origin)
    }

    func disable(coin: Coin) {
        guard let wallet = wallets[coin] else {
            return
        }

        walletManager.delete(wallets: [wallet])
    }

    func storeCoinToEnable(coin: Coin) {
        coinToEnable = coin
    }

}

extension ManageWalletsService {

    struct State {
        let featuredItems: [Item]
        let items: [Item]

        func item(coin: Coin) -> Item? {
            let allItems = featuredItems + items
            return allItems.first { item in
                item.coin == coin
            }
        }

        static var empty: State {
            State(featuredItems: [], items: [])
        }
    }

    struct Item {
        let coin: Coin
        var state: ItemState

        init(coin: Coin, state: ItemState) {
            self.coin = coin
            self.state = state
        }
    }

    enum ItemState: CustomStringConvertible {
        case noAccount
        case hasAccount(account: Account, hasWallet: Bool)
    }

}

import RxSwift
import RxRelay

class ManageWalletsService {
    private let coinManager: ICoinManager
    private let walletManager: IWalletManager
    private let accountManager: IAccountManager
    private let derivationSettingsManager: IDerivationSettingsManager

    private let disposeBag = DisposeBag()
    private var wallets = [Coin: Wallet]()

    private let stateRelay = PublishRelay<State>()

    var state = State.empty {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(coinManager: ICoinManager, walletManager: IWalletManager, accountManager: IAccountManager, derivationSettingsManager: IDerivationSettingsManager) {
        self.coinManager = coinManager
        self.walletManager = walletManager
        self.accountManager = accountManager
        self.derivationSettingsManager = derivationSettingsManager

        accountManager.accountsObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] _ in
                    self?.syncState()
                })
                .disposed(by: disposeBag)

        coinManager.coinAddedObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] _ in
                    self?.syncState()
                })
                .disposed(by: disposeBag)

        for wallet in walletManager.wallets {
            wallets[wallet.coin] = wallet
        }

        syncState()
    }

    private func account(coin: Coin) -> Account? {
        accountManager.accounts.first { coin.type.canSupport(accountType: $0.type) }
    }

    private func item(coin: Coin) -> Item {
        let hasWallet = wallets[coin] != nil
        let hasAccount = account(coin: coin) != nil
        let state: ItemState = hasAccount ? .hasAccount(hasWallet: hasWallet) : .noAccount
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

}

extension ManageWalletsService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    func enable(coin: Coin, derivationSetting: DerivationSetting? = nil) throws {
        guard let account = account(coin: coin) else {
            throw EnableCoinError.noAccount
        }

        if account.origin == .restored, let setting = derivationSettingsManager.setting(coinType: coin.type) {
            guard let derivationSetting = derivationSetting else {
                throw EnableCoinError.derivationNotConfirmed(currentDerivation: setting.derivation)
            }

            derivationSettingsManager.save(setting: derivationSetting)
        }

        let wallet = Wallet(coin: coin, account: account)

        walletManager.save(wallets: [wallet])
        wallets[coin] = wallet

        syncState()
    }

    func disable(coin: Coin) {
        guard let wallet = wallets[coin] else {
            return
        }

        walletManager.delete(wallets: [wallet])
        wallets.removeValue(forKey: coin)

        syncState()
    }

}

extension ManageWalletsService {

    struct State {
        let featuredItems: [Item]
        let items: [Item]

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
        case hasAccount(hasWallet: Bool)
    }

    enum EnableCoinError: Error {
        case noAccount
        case derivationNotConfirmed(currentDerivation: MnemonicDerivation)
    }

}

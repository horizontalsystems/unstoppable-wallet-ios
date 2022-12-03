import RxSwift
import RxRelay
import MarketKit
import EvmKit

class ManageWalletsService {
    private let account: Account
    private let marketKit: MarketKit.Kit
    private let walletManager: WalletManager
    private let enableCoinService: EnableCoinService
    private let disposeBag = DisposeBag()

    private var fullCoins = [FullCoin]()
    private var wallets = Set<Wallet>()
    private var filter: String = ""

    private let itemsRelay = PublishRelay<[Item]>()
    private let cancelEnableCoinRelay = PublishRelay<Coin>()

    var items: [Item] = [] {
        didSet {
            itemsRelay.accept(items)
        }
    }

    init?(marketKit: MarketKit.Kit, walletManager: WalletManager, accountManager: AccountManager, enableCoinService: EnableCoinService) {
        guard let account = accountManager.activeAccount else {
            return nil
        }

        self.account = account
        self.marketKit = marketKit
        self.walletManager = walletManager
        self.enableCoinService = enableCoinService

        subscribe(disposeBag, walletManager.activeWalletsUpdatedObservable) { [weak self] wallets in
            self?.handleUpdated(wallets: wallets)
        }
        subscribe(disposeBag, enableCoinService.enableCoinObservable) { [weak self] configuredTokens, restoreSettings in
            self?.handleEnableCoin(configuredTokens: configuredTokens, restoreSettings: restoreSettings)
        }
        subscribe(disposeBag, enableCoinService.disableCoinObservable) { [weak self] coin in
            self?.handleDisable(coin: coin)
        }
        subscribe(disposeBag, enableCoinService.cancelEnableCoinObservable) { [weak self] fullCoin in
            self?.handleCancelEnable(fullCoin: fullCoin)
        }

        sync(wallets: walletManager.activeWallets)
        syncFullCoins()
        sortFullCoins()
        syncState()
    }

    private func fetchFullCoins() -> [FullCoin] {
        do {
            let fullCoins: [FullCoin]

            if filter.trimmingCharacters(in: .whitespaces).isEmpty {
                let marketFullCoins = try marketKit.fullCoins(filter: "", limit: 100).filter { fullCoin in
                    !fullCoin.eligibleTokens(accountType: account.type).isEmpty
                }
                let testNetFullCoins = TestNetManager.instance.nativeTokens().map { $0.fullCoin }

                let featuredFullCoins = marketFullCoins + testNetFullCoins

                let featuredCoins = featuredFullCoins.map { $0.coin }
                let enabledFullCoins = try marketKit.fullCoins(coinUids: wallets.filter { !featuredCoins.contains($0.coin) }.map { $0.coin.uid })

                let customFullCoins = wallets.map { $0.token }.filter { $0.isCustom }.map { $0.fullCoin }

                fullCoins = featuredFullCoins + enabledFullCoins + customFullCoins
            } else if let ethAddress = try? EvmKit.Address(hex: filter) {
                let address = ethAddress.hex
                let tokens = try marketKit.tokens(reference: address)
                let coinUids = Array(Set(tokens.map { $0.coin.uid }))
                fullCoins = try marketKit.fullCoins(coinUids: coinUids)
            } else {
                fullCoins = try marketKit.fullCoins(filter: filter, limit: 20)
            }

            return fullCoins.map { fullCoin in
                let eligibleTokens = fullCoin.eligibleTokens(accountType: account.type)
                return FullCoin(coin: fullCoin.coin, tokens: eligibleTokens)
            }
        } catch {
            return []
        }
    }

    private func merge(fullCoins: [FullCoin]) -> [FullCoin] {
        var dictionary = [Coin: [Token]]()
        for coin in fullCoins {
            if dictionary[coin.coin] == nil {
                dictionary[coin.coin] = coin.tokens
            } else {
                dictionary[coin.coin]?.append(contentsOf: coin.tokens)
            }
        }
        return dictionary.map { coin, tokens in FullCoin(coin: coin, tokens: tokens) }
    }

    private func syncFullCoins() {
        fullCoins = fetchFullCoins()
    }

    private func isEnabled(coin: Coin) -> Bool {
        wallets.contains { $0.coin == coin }
    }

    private func sortFullCoins() {
        fullCoins.sort(filter: filter) { isEnabled(coin: $0) }
    }

    private func sync(wallets: [Wallet]) {
        self.wallets = Set(wallets)
    }

    private func hasSettingsOrTokens(tokens: [Token]) -> Bool {
        if tokens.count == 1 {
            let token = tokens[0]
            return token.blockchainType.coinSettingType != nil || token.type != .native
        } else {
            return true
        }
    }

    private func item(fullCoin: FullCoin) -> Item {
        let itemState: ItemState

        if fullCoin.tokens.isEmpty {
            itemState = .unsupported
        } else {
            let enabled = isEnabled(coin: fullCoin.coin)
            itemState = .supported(enabled: enabled, hasSettings: enabled && hasSettingsOrTokens(tokens: fullCoin.tokens))
        }

        return Item(fullCoin: fullCoin, state: itemState)
    }

    private func syncState() {
        items = fullCoins.map { item(fullCoin: $0) }
    }

    private func handleUpdated(wallets: [Wallet]) {
        sync(wallets: wallets)

        let newFullCoins = fetchFullCoins()

        if newFullCoins.count > fullCoins.count {
            fullCoins = newFullCoins
            sortFullCoins()
        }

        syncState()
    }

    private func handleEnableCoin(configuredTokens: [ConfiguredToken], restoreSettings: RestoreSettings) {
        guard let coin = configuredTokens.first?.token.coin else {
            return
        }

        if !restoreSettings.isEmpty && configuredTokens.count == 1 {
            enableCoinService.save(restoreSettings: restoreSettings, account: account, blockchainType: configuredTokens[0].token.blockchainType)
        }

        let existingWallets = wallets.filter { $0.coin == coin }
        let existingConfiguredTokens = existingWallets.map { $0.configuredToken }

        let newConfiguredTokens = configuredTokens.filter { !existingConfiguredTokens.contains($0) }
        let removedWallets = existingWallets.filter { !configuredTokens.contains($0.configuredToken) }

        let newWallets = newConfiguredTokens.map { Wallet(configuredToken: $0, account: account) }

        if !newWallets.isEmpty || !removedWallets.isEmpty {
            walletManager.handle(newWallets: newWallets, deletedWallets: Array(removedWallets))
        }
    }

    private func handleDisable(coin: Coin) {
        let walletsToDelete = wallets.filter { $0.coin == coin }
        walletManager.delete(wallets: Array(walletsToDelete))

        cancelEnableCoinRelay.accept(coin)
    }

    private func handleCancelEnable(fullCoin: FullCoin) {
        if !isEnabled(coin: fullCoin.coin) {
            cancelEnableCoinRelay.accept(fullCoin.coin)
        }
    }

}

extension ManageWalletsService {

    var itemsObservable: Observable<[Item]> {
        itemsRelay.asObservable()
    }

    var cancelEnableCoinObservable: Observable<Coin> {
        cancelEnableCoinRelay.asObservable()
    }

    var accountType: AccountType {
        account.type
    }

    func set(filter: String) {
        self.filter = filter

        syncFullCoins()
        sortFullCoins()
        syncState()
    }

    func enable(uid: String) {
        guard let fullCoin = fullCoins.first(where: { $0.coin.uid == uid }) else {
            return
        }

        enableCoinService.enable(fullCoin: fullCoin, accountType: account.type, account: account)
    }

    func disable(uid: String) {
        let walletsToDelete = wallets.filter { $0.coin.uid == uid }
        walletManager.delete(wallets: Array(walletsToDelete))
    }

    func configure(uid: String) {
        guard let fullCoin = fullCoins.first(where: { $0.coin.uid == uid }) else {
            return
        }

        let coinWallets = wallets.filter { $0.coin.uid == uid }
        enableCoinService.configure(fullCoin: fullCoin, accountType: account.type, configuredTokens: coinWallets.map { $0.configuredToken })
    }

}

extension ManageWalletsService {

    struct Item {
        let fullCoin: FullCoin
        let state: ItemState
    }

    enum ItemState {
        case unsupported
        case supported(enabled: Bool, hasSettings: Bool)
    }

}

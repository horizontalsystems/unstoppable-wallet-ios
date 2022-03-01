import Foundation
import RxSwift
import RxRelay
import MarketKit

class CoinPageService {
    let fullCoin: FullCoin
    private let favoritesManager: FavoritesManager
    private let accountManager: IAccountManager
    private let walletManager: WalletManager
    private let enableCoinService: EnableCoinService
    private let disposeBag = DisposeBag()

    private let favoriteRelay = PublishRelay<Bool>()
    private(set) var favorite: Bool = false {
        didSet {
            if oldValue != favorite {
                favoriteRelay.accept(favorite)
            }
        }
    }

    private let walletStateRelay = PublishRelay<WalletState>()
    private(set) var walletState: WalletState = .unsupported {
        didSet {
            walletStateRelay.accept(walletState)
        }
    }

    init(fullCoin: FullCoin, favoritesManager: FavoritesManager, accountManager: IAccountManager, walletManager: WalletManager, enableCoinService: EnableCoinService) {
        self.fullCoin = fullCoin
        self.favoritesManager = favoritesManager
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.enableCoinService = enableCoinService

        subscribe(disposeBag, favoritesManager.coinUidsUpdatedObservable) { [weak self] in self?.syncFavorite() }
        subscribe(disposeBag, walletManager.activeWalletsUpdatedObservable) { [weak self] _ in self?.syncWalletState() }
        subscribe(disposeBag, enableCoinService.enableCoinObservable) { [weak self] configuredPlatformsCoins, restoreSettings in
            self?.handleEnableCoin(configuredPlatformCoins: configuredPlatformsCoins, restoreSettings: restoreSettings)
        }

        syncFavorite()
        syncWalletState()
    }

    private func syncFavorite() {
        favorite = favoritesManager.isFavorite(coinUid: fullCoin.coin.uid)
    }

    private var enabledWallets: [Wallet] {
        let platforms = fullCoin.supportedPlatforms
        return walletManager.activeWallets.filter { platforms.contains($0.platform) }
    }

    private func syncWalletState() {
        guard let activeAccount = accountManager.activeAccount else {
            walletState = .noActiveAccount
            return
        }

        if activeAccount.watchAccount {
            walletState = .watchAccount
        } else if fullCoin.supportedPlatforms.isEmpty {
            walletState = .unsupported
        } else {
            walletState = .supported(added: !enabledWallets.isEmpty)
        }
    }

    private func handleEnableCoin(configuredPlatformCoins: [ConfiguredPlatformCoin], restoreSettings: RestoreSettings) {
        guard let account = accountManager.activeAccount else {
            return
        }

        if !restoreSettings.isEmpty && configuredPlatformCoins.count == 1 {
            enableCoinService.save(restoreSettings: restoreSettings, account: account, coinType: configuredPlatformCoins[0].platformCoin.coinType)
        }

        let wallets = configuredPlatformCoins.map { Wallet(configuredPlatformCoin: $0, account: account) }
        walletManager.handle(newWallets: wallets, deletedWallets: [])
    }

}

extension CoinPageService {

    var favoriteObservable: Observable<Bool> {
        favoriteRelay.asObservable()
    }

    var walletStateObservable: Observable<WalletState> {
        walletStateRelay.asObservable()
    }

    func toggleFavorite() {
        if favorite {
            favoritesManager.remove(coinUid: fullCoin.coin.uid)
        } else {
            favoritesManager.add(coinUid: fullCoin.coin.uid)
        }
    }

    func addWallet() {
        guard enabledWallets.isEmpty else {
            return
        }

        enableCoinService.enable(fullCoin: fullCoin, account: accountManager.activeAccount)
    }

}

extension CoinPageService {

    enum WalletState {
        case noActiveAccount
        case watchAccount
        case unsupported
        case supported(added: Bool)
    }

}

import Foundation
import RxSwift
import RxRelay
import MarketKit

class CoinPageService {
    let fullCoin: FullCoin
    private let favoritesManager: FavoritesManager
    private let accountManager: AccountManager
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

    init(fullCoin: FullCoin, favoritesManager: FavoritesManager, accountManager: AccountManager, walletManager: WalletManager, enableCoinService: EnableCoinService) {
        self.fullCoin = fullCoin
        self.favoritesManager = favoritesManager
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.enableCoinService = enableCoinService

        subscribe(disposeBag, favoritesManager.coinUidsUpdatedObservable) { [weak self] in self?.syncFavorite() }
        subscribe(disposeBag, walletManager.activeWalletsUpdatedObservable) { [weak self] _ in self?.syncWalletState() }
        subscribe(disposeBag, enableCoinService.enableCoinObservable) { [weak self] configuredTokens, restoreSettings in
            self?.handleEnableCoin(configuredTokens: configuredTokens, restoreSettings: restoreSettings)
        }

        syncFavorite()
        syncWalletState()
    }

    private func syncFavorite() {
        favorite = favoritesManager.isFavorite(coinUid: fullCoin.coin.uid)
    }

    private var enabledWallets: [Wallet] {
        let tokens = fullCoin.supportedTokens
        return walletManager.activeWallets.filter { tokens.contains($0.token) }
    }

    private func syncWalletState() {
        guard let activeAccount = accountManager.activeAccount else {
            walletState = .noActiveAccount
            return
        }

        if activeAccount.watchAccount {
            walletState = .watchAccount
        } else if fullCoin.eligibleTokens(accountType: activeAccount.type).isEmpty {
            walletState = .unsupported
        } else {
            walletState = .supported(added: !enabledWallets.isEmpty)
        }
    }

    private func handleEnableCoin(configuredTokens: [ConfiguredToken], restoreSettings: RestoreSettings) {
        guard let account = accountManager.activeAccount else {
            return
        }

        if !restoreSettings.isEmpty && configuredTokens.count == 1 {
            enableCoinService.save(restoreSettings: restoreSettings, account: account, blockchainType: configuredTokens[0].token.blockchainType)
        }

        let wallets = configuredTokens.map { Wallet(configuredToken: $0, account: account) }
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

        guard let account = accountManager.activeAccount else {
            return
        }

        enableCoinService.enable(fullCoin: fullCoin, accountType: account.type, account: account)
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

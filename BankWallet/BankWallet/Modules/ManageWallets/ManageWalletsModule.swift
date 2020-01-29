protocol IManageWalletsView: class {
    func setCloseButton(visible: Bool)
    func set(featuredViewItems: [CoinToggleViewItem], viewItems: [CoinToggleViewItem])

    func showNoAccount(coin: Coin, predefinedAccountType: PredefinedAccountType)
    func show(error: Error)
    func showSuccess()
}

protocol IManageWalletsViewDelegate {
    func onLoad()

    func onEnable(viewItem: CoinToggleViewItem)
    func onDisable(viewItem: CoinToggleViewItem)
    func onSelect(viewItem: CoinToggleViewItem)

    func onTapCloseButton()

    func onSelectNewAccount(predefinedAccountType: PredefinedAccountType)
    func onSelectRestoreAccount(predefinedAccountType: PredefinedAccountType)
}

protocol IManageWalletsInteractor {
    var coins: [Coin] { get }
    var featuredCoins: [Coin] { get }
    var accounts: [Account] { get }
    var wallets: [Wallet] { get }

    func save(wallet: Wallet)
    func delete(wallet: Wallet)

    func createAccount(predefinedAccountType: PredefinedAccountType) throws -> Account
    func createRestoredAccount(accountType: AccountType) -> Account
    func save(account: Account)

    func coinSettings(coinType: CoinType) -> CoinSettings
}

protocol IManageWalletsInteractorDelegate: class {
}

protocol IManageWalletsRouter {
    func showSettings(delegate: IBlockchainSettingsDelegate)
    func showRestore(predefinedAccountType: PredefinedAccountType, delegate: ICredentialsCheckDelegate)
    func close()
    func closePresented()
}

protocol IManageWalletsPresenterState {
    var allCoins: [Coin] { get set }
    var wallets: [Wallet] { get set }
    var coins: [Coin] { get }
    func enable(wallet: Wallet)
    func disable(index: Int)
    func move(from: Int, to: Int)
}

class CoinToggleViewItem {
    let coin: Coin
    var state: CoinToggleViewItemState

    init(coin: Coin, state: CoinToggleViewItemState) {
        self.coin = coin
        self.state = state
    }
}

enum CoinToggleViewItemState: CustomStringConvertible {
    case toggleHidden
    case toggleVisible(enabled: Bool)

    var description: String {
        switch self {
        case .toggleHidden: return "hidden"
        case .toggleVisible(let enabled): return "visible_\(enabled)"
        }
    }

}

class ManageWalletsModule {

    enum PresentationMode {
        case presented
        case pushed
    }

}

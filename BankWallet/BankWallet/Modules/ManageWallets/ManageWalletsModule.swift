protocol IManageWalletsView: class {
    func updateUI()
    func showNoAccount(coin: Coin)
    func show(error: Error)
}

protocol IManageWalletsViewDelegate {
    func viewDidLoad()

    var popularItemsCount: Int { get }
    func popularItem(index: Int) -> ManageWalletViewItem

    var itemsCount: Int { get }
    func item(index: Int) -> ManageWalletViewItem

    func enablePopularItem(index: Int)
    func disablePopularItem(index: Int)

    func enableItem(index: Int)
    func disableItem(index: Int)

    func saveChanges()
    func close()

    func didTapNew()
    func didTapRestore()
    func didCancelCreate()
}

protocol IManageWalletsInteractor {
    var coins: [Coin] { get }
    var wallets: [Wallet] { get }
    func wallet(coin: Coin) -> Wallet?
    func enable(wallets: [Wallet])
    func createAccount(defaultAccountType: DefaultAccountType) throws -> Account
    func createRestoredAccount(accountType: AccountType, defaultSyncMode: SyncMode?) -> Account
    func createWallet(coin: Coin, account: Account) -> Wallet
}

protocol IManageWalletsInteractorDelegate: class {
}

protocol IManageWalletsRouter {
    func showRestore(defaultAccountType: DefaultAccountType, delegate: IRestoreAccountTypeDelegate)
    func close()
}

protocol IManageWalletsPresenterState {
    var allCoins: [Coin] { get set }
    var wallets: [Wallet] { get set }
    var coins: [Coin] { get }
    func enable(wallet: Wallet)
    func disable(index: Int)
    func move(from: Int, to: Int)
}

class ManageWalletItem {
    let coin: Coin
    var wallet: Wallet?

    init(coin: Coin, wallet: Wallet?) {
        self.coin = coin
        self.wallet = wallet
    }
}

struct ManageWalletViewItem {
    let coin: Coin
    let enabled: Bool
}

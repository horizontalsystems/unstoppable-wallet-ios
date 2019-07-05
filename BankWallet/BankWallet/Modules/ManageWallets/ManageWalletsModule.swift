protocol IManageWalletsView: class {
    func updateUI()
    func show(error: String)
}

protocol IManageWalletsViewDelegate {
    func viewDidLoad()
    var walletsCount: Int { get }
    var coinsCount: Int { get }
    func wallet(forIndex index: Int) -> Wallet
    func coin(forIndex index: Int) -> Coin
    func enableCoin(atIndex index: Int)
    func disableWallet(atIndex index: Int)
    func moveWallet(from fromIndex: Int, to toIndex: Int)
    func saveChanges()
    func onClose()
}

protocol IManageWalletsRouter {
    func showCreateAccount(coin: Coin, delegate: ICreateAccountDelegate)
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

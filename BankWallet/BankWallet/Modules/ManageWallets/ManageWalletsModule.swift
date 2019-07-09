protocol IManageWalletsView: class {
    func updateUI()
    func showCreateAccount(coin: Coin, showNew: Bool)
    func show(error: Error)
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
    func didSelectNew()
    func didSelectRestore()
}

protocol IManageWalletsRouter {
//    func showRestore(type: PredefinedAccountType, delegate: IRestoreAccountTypeDelegate)
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

protocol ICreateWalletView: class {
    func set(viewItems: [CreateWalletViewItem])
}

protocol ICreateWalletViewDelegate {
    func viewDidLoad()
    func didTap(index: Int)
}

protocol ICreateWalletInteractor {
    var featuredCoins: [Coin] { get }
    func createWallet(coin: Coin)
}

protocol ICreateWalletRouter {
    func showMain()
}

struct CreateWalletViewItem {
    let title: String
    let code: String
}

class CreateWalletState {
    var coins: [Coin] = []
}

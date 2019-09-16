protocol ICreateWalletView: class {
    func set(viewItems: [CreateWalletViewItem])
}

protocol ICreateWalletViewDelegate {
    func viewDidLoad()
    func didTap(index: Int)
    func didTapCreateButton()
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
    let selected: Bool
}

class CreateWalletState {
    var coins: [Coin] = []
    var selectedIndex: Int = 0
}

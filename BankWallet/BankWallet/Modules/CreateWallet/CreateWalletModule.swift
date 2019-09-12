protocol ICreateWalletView: class {
    func set(viewItems: [CreateWalletViewItem])
    func set(createButtonEnabled: Bool)
}

protocol ICreateWalletViewDelegate {
    func viewDidLoad()
    func didToggle(index: Int, isOn: Bool)
    func didTapCreateButton()
}

protocol ICreateWalletInteractor {
    var featuredCoins: [FeaturedCoin] { get }
    func createWallet(coins: [Coin])
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
    var enabledIndexes: Set<Int> = []
}

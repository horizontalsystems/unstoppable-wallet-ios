protocol ICreateWalletView: class {
    func set(viewItems: [CreateWalletViewItem])
    func set(createButtonEnabled: Bool)
}

protocol ICreateWalletViewDelegate {
    func viewDidLoad()
    func didToggle(index: Int, isOn: Bool)
}

protocol ICreateWalletInteractor {
    var featuredCoins: [FeaturedCoin] { get }
}

protocol ICreateWalletRouter {
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

protocol IManageCoinsView: class {
    func updateUI()
    func show(error: String)
}

protocol IManageCoinsViewDelegate {
    func viewDidLoad()
    var enabledCoinsCount: Int { get }
    var disabledCoinsCount: Int { get }
    func enabledItem(forIndex index: Int) -> Coin
    func disabledItem(forIndex index: Int) -> Coin
    func enable(atIndex index: Int)
    func disable(atIndex index: Int)
    func move(from fromIndex: Int, to toIndex: Int)
    func saveChanges()
    func onClose()
}

protocol IManageCoinsInteractor {
    func loadCoins()
    func save(enabledCoins: [Coin])
}

protocol IManageCoinsInteractorDelegate: class {
    func didLoad(allCoins: [Coin])
    func didLoad(enabledCoins: [Coin])
    func didSaveCoins()
    func didFailToSaveCoins()
}

protocol IManageCoinsRouter {
    func close()
}

protocol IManageCoinsPresenterState {
    var allCoins: [Coin] { get set }
    var enabledCoins: [Coin] { get set }
    var disabledCoins: [Coin] { get }
    func enable(coin: Coin)
    func disable(coin: Coin)
    func move(coin: Coin, to index: Int)
}

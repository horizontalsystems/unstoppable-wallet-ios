import Foundation

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
    func enable(coin: Coin)
    func disable(coin: Coin)
    func move(coin: Coin, to: Int)
    func saveChanges()
}

protocol IManageCoinsInteractor {
    func loadCoins()
    func save(enabledCoins: [Coin])
}

protocol IManageCoinsInteractorDelegate: class {
    func didLoadCoins(all: [Coin], enabled: [Coin])
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

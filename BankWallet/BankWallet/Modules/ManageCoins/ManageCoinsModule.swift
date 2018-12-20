import Foundation

protocol IManageCoinsView: class {
    func showCoins(enabled: [Coin], disabled: [Coin])
}

protocol IManageCoinsViewDelegate {
    func viewDidLoad()
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
}

protocol IManageCoinsRouter {
    func close()
}

protocol IManageCoinsPresenterState {
    var allCoins: [Coin] { get set }
    var enabledCoins: [Coin] { get set }
    var disabledCoins: [Coin] { get }
    func add(coin: Coin)
    func remove(coin: Coin)
    func move(coin: Coin, to index: Int)
}

class ManageCoinsPresenterState: IManageCoinsPresenterState {
    var allCoins: [Coin] = []
    var enabledCoins: [Coin] = []
    var disabledCoins: [Coin] {
        var disabledCoins = allCoins
        disabledCoins.removeAll(where: { enabledCoins.contains($0) })
        return disabledCoins
    }

    func add(coin: Coin) {
        enabledCoins.append(coin)
    }

    func remove(coin: Coin) {
        if let index = enabledCoins.firstIndex(of: coin) {
            enabledCoins.remove(at: index)
        }
    }

    func move(coin: Coin, to index: Int) {
        remove(coin: coin)
        enabledCoins.insert(coin, at: index)
    }

}

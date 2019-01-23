class ManageCoinsPresenterState: IManageCoinsPresenterState {
    var allCoins: [Coin] = [] {
        didSet {
            fillDisabledCoins()
        }
    }
    var enabledCoins: [Coin] = [] {
        didSet {
            fillDisabledCoins()
        }
    }

    var disabledCoins: [Coin] = []

    func enable(coin: Coin) {
        enabledCoins.append(coin)
        fillDisabledCoins()
    }

    func disable(coin: Coin) {
        if let index = enabledCoins.firstIndex(of: coin) {
            enabledCoins.remove(at: index)
            fillDisabledCoins()
        }
    }

    func move(coin: Coin, to index: Int) {
        if let originalIndex = enabledCoins.firstIndex(of: coin) {
            enabledCoins.remove(at: originalIndex)
            enabledCoins.insert(coin, at: index)
        }
    }

    private func fillDisabledCoins() {
        var coins = allCoins
        coins.removeAll(where: { enabledCoins.contains($0) })
        disabledCoins = coins
    }

}

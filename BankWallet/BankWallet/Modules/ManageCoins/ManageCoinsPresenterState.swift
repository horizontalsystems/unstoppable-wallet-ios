class ManageCoinsPresenterState: IManageCoinsPresenterState {
    var allCoins: [Coin] = []
    var enabledCoins: [Coin] = []

    var disabledCoins: [Coin] {
        var disabledCoins = allCoins
        disabledCoins.removeAll(where: { enabledCoins.contains($0) })
        return disabledCoins
    }

    func enable(coin: Coin) {
        enabledCoins.append(coin)
    }

    func disable(coin: Coin) {
        if let index = enabledCoins.firstIndex(of: coin) {
            enabledCoins.remove(at: index)
        }
    }

    func move(coin: Coin, to index: Int) {
        disable(coin: coin)
        enabledCoins.insert(coin, at: index)
    }

}

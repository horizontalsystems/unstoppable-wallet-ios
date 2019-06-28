class ManageWalletsPresenterState: IManageWalletsPresenterState {

    var allCoins: [Coin] = [] {
        didSet {
            fillDisabledCoins()
        }
    }

    var wallets: [Wallet] = [] {
        didSet {
            fillDisabledCoins()
        }
    }

    var coins: [Coin] = []

    func enable(wallet: Wallet) {
        wallets.append(wallet)
        fillDisabledCoins()
    }

    func disable(index: Int) {
        wallets.remove(at: index)
        fillDisabledCoins()
    }

    func move(from: Int, to: Int) {
        let wallet = wallets.remove(at: from)
        wallets.insert(wallet, at: to)
    }

    private func fillDisabledCoins() {
        var coins = allCoins
        coins.removeAll { coin in wallets.contains { wallet in wallet.coin == coin } }
        self.coins = coins
    }

}

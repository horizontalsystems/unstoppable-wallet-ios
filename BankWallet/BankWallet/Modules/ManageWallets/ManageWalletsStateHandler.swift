class ManageWalletsStateHandler {

    func remainingCoins(allCoins: [Coin], wallets: [Wallet]) -> [Coin] {
        return allCoins.filter { coin in
            !wallets.contains { $0.coin == coin }
        }
    }

}

class TransactionRecordPoolRepo {
    private var pools = [Coin: TransactionRecordPool]()
    private var activePoolCoins = [Coin]()

    var activePools: [TransactionRecordPool] {
        return activePoolCoins.compactMap { pools[$0] }
    }

    var allPools: [TransactionRecordPool] {
        return Array(pools.values)
    }

    func activatePools(coins: [Coin]) {
        // remove pools for unused coins
        pools.keys.forEach({ poolCoin in
            if (!coins.contains(poolCoin)) {
                pools.removeValue(forKey: poolCoin)
            }
        })

        coins.forEach { coin in
            if pools[coin] == nil {
                pools[coin] = TransactionRecordPool(state: TransactionRecordPoolState(coin: coin))
            }
        }

        activePoolCoins = coins
    }

    func pool(byCoin coin: Coin) -> TransactionRecordPool? {
        return pools[coin]
    }

    func isPoolActive(coin: Coin) -> Bool {
        return activePoolCoins.contains(coin)
    }

}

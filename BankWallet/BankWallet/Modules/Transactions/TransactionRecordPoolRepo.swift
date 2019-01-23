class TransactionRecordPoolRepo {
    private var pools = [CoinCode: TransactionRecordPool]()
    private var activePoolCoinCodes = [CoinCode]()

    var activePools: [TransactionRecordPool] {
        return activePoolCoinCodes.compactMap { pools[$0] }
    }

    var allPools: [TransactionRecordPool] {
        return Array(pools.values)
    }

    func activatePools(coinCodes: [CoinCode]) {
        coinCodes.forEach { coinCode in
            if pools[coinCode] == nil {
                pools[coinCode] = TransactionRecordPool(state: TransactionRecordPoolState(coinCode: coinCode))
            }
        }

        activePoolCoinCodes = coinCodes
    }

    func pool(byCoinCode coinCode: CoinCode) -> TransactionRecordPool? {
        return pools[coinCode]
    }

    func isPoolActive(coinCode: CoinCode) -> Bool {
        return activePoolCoinCodes.contains(coinCode)
    }

}

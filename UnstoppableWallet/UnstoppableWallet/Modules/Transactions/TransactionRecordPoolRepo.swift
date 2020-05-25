class TransactionRecordPoolRepo {
    private var pools = [Wallet: TransactionRecordPool]()
    private var activePoolWallets = [Wallet]()

    var activePools: [TransactionRecordPool] {
        return activePoolWallets.compactMap { pools[$0] }
    }

    var allPools: [TransactionRecordPool] {
        return Array(pools.values)
    }

    func activatePools(wallets: [Wallet]) {
        wallets.forEach { wallet in
            if pools[wallet] == nil {
                pools[wallet] = TransactionRecordPool(state: TransactionRecordPoolState(wallet: wallet))
            }
        }

        activePoolWallets = wallets
    }

    func pool(byWallet wallet: Wallet) -> TransactionRecordPool? {
        return pools[wallet]
    }

    func isPoolActive(wallet: Wallet) -> Bool {
        return activePoolWallets.contains(wallet)
    }

    func deactivateAllPools() {
        pools.removeAll()
    }

}

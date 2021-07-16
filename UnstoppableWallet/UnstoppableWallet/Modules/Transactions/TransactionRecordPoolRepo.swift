class TransactionRecordPoolRepo {
    private var pools = [TransactionWallet: TransactionRecordPool]()
    private var activePoolWallets = [TransactionWallet]()

    var activePools: [TransactionRecordPool] {
        activePoolWallets.compactMap { pools[$0] }
    }

    var allPools: [TransactionRecordPool] {
        Array(pools.values)
    }

    func activatePools(wallets: [TransactionWallet]) {
        wallets.forEach { wallet in
            if pools[wallet] == nil {
                pools[wallet] = TransactionRecordPool(state: TransactionRecordPoolState(wallet: wallet))
            }
        }

        activePoolWallets = wallets
    }

    func pool(byWallet wallet: TransactionWallet) -> TransactionRecordPool? {
        pools[wallet]
    }

    func isPoolActive(wallet: TransactionWallet) -> Bool {
        activePoolWallets.contains(wallet)
    }

    func deactivateAllPools() {
        pools.removeAll()
    }

}

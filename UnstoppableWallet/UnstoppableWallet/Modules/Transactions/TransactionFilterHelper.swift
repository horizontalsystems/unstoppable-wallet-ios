import RxSwift

class TransactionFilterHelper {

    var types = TransactionTypeFilter.allCases
    var selectedTypeIndex = 0

    var wallets = [TransactionWallet]()
    var selectedWalletIndex: Int? = nil

}

extension TransactionFilterHelper {

    var typeFilters: (types: [TransactionTypeFilter], selected: Int) {
        (types: types, selected: selectedTypeIndex)
    }

    var walletFilters: (wallets: [TransactionWallet], selected: Int?) {
        (wallets: wallets, selected: selectedWalletIndex)
    }

    var selectedType: TransactionTypeFilter {
        types[selectedTypeIndex]
    }

    var selectedWallet: TransactionWallet? {
        guard let index = selectedWalletIndex, wallets.count > index else {
            return nil
        }

        return wallets[index]
    }

    func set(wallets: [Wallet]) {
        let newWallets = wallets
                .sorted { wallet, wallet2 in wallet.coin.code < wallet2.coin.code }
                .map { TransactionWallet(coin: $0.platformCoin, source: $0.transactionSource, badge: $0.badge) }

        if let selectedWallet = selectedWallet, let index = newWallets.firstIndex(of: selectedWallet) {
            selectedWalletIndex = index
        } else {
            selectedWalletIndex = nil
        }

        if !newWallets.contains(where: { self.wallets.contains($0) }) {
            // If no new wallet is in previous list of wallets,
            // we reset the type filter
            selectedTypeIndex = 0
        }

        self.wallets = newWallets
    }

    func set(selectedTypeIndex: Int) {
        self.selectedTypeIndex = selectedTypeIndex
    }

    func set(selectedWalletIndex: Int?) {
        self.selectedWalletIndex = selectedWalletIndex
    }

}

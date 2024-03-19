import Combine
import MarketKit

class TransactionBlockchainSelectViewModel: ObservableObject {
    private let transactionFilterViewModel: TransactionFilterViewModel
    private let walletManager = App.shared.walletManager

    let blockchains: [Blockchain]

    init(transactionFilterViewModel: TransactionFilterViewModel) {
        self.transactionFilterViewModel = transactionFilterViewModel

        blockchains = Array(Set(walletManager.activeWallets.map(\.token.blockchain)))
    }

    var currentBlockchain: Blockchain? {
        transactionFilterViewModel.blockchain
    }

    func set(currentBlockchain: Blockchain?) {
        transactionFilterViewModel.set(blockchain: currentBlockchain)
    }
}

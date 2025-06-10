import Combine
import MarketKit

class BalanceErrorViewModifierModel: ObservableObject {
    private let adapterManager = App.shared.adapterManager
    private let btcBlockchainManager = App.shared.btcBlockchainManager
    private let evmBlockchainManager = App.shared.evmBlockchainManager

    @Published var item: Item?

    func handle(wallet: Wallet, error: Error) {
        var sourceType: SourceType?

        if let blockchain = btcBlockchainManager.blockchain(token: wallet.token) {
            sourceType = .btc(blockchain: blockchain)
        } else if let blockchain = evmBlockchainManager.blockchain(token: wallet.token) {
            sourceType = .evm(blockchain: blockchain)
        }

        item = Item(wallet: wallet, error: error.localizedDescription, sourceType: sourceType)
    }

    func refresh(wallet: Wallet) {
        adapterManager.refresh(wallet: wallet)
    }
}

extension BalanceErrorViewModifierModel {
    struct Item: Identifiable {
        let wallet: Wallet
        let error: String
        let sourceType: SourceType?

        var id: String {
            wallet.token.coin.uid + wallet.token.blockchainType.uid
        }
    }

    enum SourceType {
        case btc(blockchain: Blockchain)
        case evm(blockchain: Blockchain)
    }
}

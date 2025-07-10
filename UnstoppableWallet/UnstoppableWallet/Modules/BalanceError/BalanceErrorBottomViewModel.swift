import Combine
import MarketKit

class BalanceErrorBottomViewModel: ObservableObject {
    private let adapterManager = Core.shared.adapterManager
    private let btcBlockchainManager = Core.shared.btcBlockchainManager
    private let evmBlockchainManager = Core.shared.evmBlockchainManager
    private let reachabilityManager = Core.shared.reachabilityManager

    let item: Item

    init(wallet: Wallet, error: Error) {
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

extension BalanceErrorBottomViewModel {
    struct Item: Identifiable {
        let wallet: Wallet
        let error: String
        let sourceType: SourceType?

        var id: String {
            wallet.id
        }
    }

    enum SourceType {
        case btc(blockchain: Blockchain)
        case evm(blockchain: Blockchain)
    }
}

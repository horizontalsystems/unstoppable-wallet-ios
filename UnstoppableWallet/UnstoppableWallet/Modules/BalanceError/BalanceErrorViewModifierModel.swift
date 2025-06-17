import Combine
import MarketKit

class BalanceErrorViewModifierModel: ObservableObject {
    private let adapterManager = Core.shared.adapterManager
    private let btcBlockchainManager = Core.shared.btcBlockchainManager
    private let evmBlockchainManager = Core.shared.evmBlockchainManager
    private let reachabilityManager = Core.shared.reachabilityManager

    @Published var item: Item?

    func handle(wallet: Wallet, state: AdapterState) {
        if !reachabilityManager.isReachable {
            HudHelper.instance.show(banner: .noInternet)
            return
        }

        guard case let .notSynced(error) = state else {
            return
        }

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
            wallet.id
        }
    }

    enum SourceType {
        case btc(blockchain: Blockchain)
        case evm(blockchain: Blockchain)
    }
}

import MarketKit
import HsExtensions

class CoinMajorHoldersService {
    let coin: Coin
    let blockchain: Blockchain
    private let marketKit: Kit
    private let evmLabelManager: EvmLabelManager
    private var tasks = Set<AnyTask>()

    @PostPublished private(set) var state: DataStatus<TokenHolders> = .loading

    init(coin: Coin, blockchain: Blockchain, marketKit: Kit, evmLabelManager: EvmLabelManager) {
        self.coin = coin
        self.blockchain = blockchain
        self.marketKit = marketKit
        self.evmLabelManager = evmLabelManager

        sync()
    }

    private func sync() {
        tasks = Set()

        state = .loading

        Task { [weak self, marketKit, coin, blockchain] in
            do {
                let holders = try await marketKit.tokenHolders(coinUid: coin.uid, blockchainUid: blockchain.uid)
                self?.state = .completed(holders)
            } catch {
                self?.state = .failed(error)
            }
        }.store(in: &tasks)
    }

}

extension CoinMajorHoldersService {

    func labeled(address: String) -> String {
        evmLabelManager.mapped(address: address)
    }

    func refresh() {
        sync()
    }

}

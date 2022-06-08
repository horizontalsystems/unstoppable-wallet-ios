import MarketKit

class BalanceErrorService {
    private let wallet: Wallet
    private let error: Error
    private let adapterManager: AdapterManager
    private let appConfigProvider: AppConfigProvider

    var item: Item?

    init(wallet: Wallet, error: Error, adapterManager: AdapterManager, appConfigProvider: AppConfigProvider, btcBlockchainManager: BtcBlockchainManager, evmBlockchainManager: EvmBlockchainManager) {
        self.wallet = wallet
        self.error = error
        self.adapterManager = adapterManager
        self.appConfigProvider = appConfigProvider

        if let blockchain = btcBlockchainManager.blockchain(token: wallet.token) {
            item = .btc(blockchain: blockchain)
        } else if let blockchain = evmBlockchainManager.blockchain(token: wallet.token) {
            item = .evm(blockchain: blockchain)
        }
    }

}

extension BalanceErrorService {

    var coinName: String {
        wallet.coin.name
    }

    var errorString: String {
        error.localizedDescription
    }

    var isSourceChangeable: Bool {
        item != nil
    }

    var contactEmail: String {
        appConfigProvider.reportEmail
    }

    func refreshWallet() {
        adapterManager.refresh(wallet: wallet)
    }

}

extension BalanceErrorService {

    enum Item {
        case btc(blockchain: Blockchain)
        case evm(blockchain: Blockchain)
    }

}

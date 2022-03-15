class BalanceErrorService {
    private let wallet: Wallet
    private let error: Error
    private let adapterManager: AdapterManager
    private let appConfigProvider: AppConfigProvider

    var blockchain: Blockchain?

    init(wallet: Wallet, error: Error, adapterManager: AdapterManager, appConfigProvider: AppConfigProvider, btcBlockchainManager: BtcBlockchainManager, evmBlockchainManager: EvmBlockchainManager) {
        self.wallet = wallet
        self.error = error
        self.adapterManager = adapterManager
        self.appConfigProvider = appConfigProvider

        if let btcBlockchain = btcBlockchainManager.blockchain(coinType: wallet.coinType) {
            blockchain = .btc(blockchain: btcBlockchain)
        } else if let evmBlockchain = evmBlockchainManager.blockchain(coinType: wallet.coinType) {
            blockchain = .evm(blockchain: evmBlockchain)
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
        blockchain != nil
    }

    var contactEmail: String {
        appConfigProvider.reportEmail
    }

    func refreshWallet() {
        adapterManager.refresh(wallet: wallet)
    }

}

extension BalanceErrorService {

    enum Blockchain {
        case btc(blockchain: BtcBlockchain)
        case evm(blockchain: EvmBlockchain)
    }

}

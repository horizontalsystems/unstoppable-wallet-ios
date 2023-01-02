import MarketKit

class BalanceErrorService {
    let wallet: Wallet
    private let error: Error
    private let adapterManager: AdapterManager
    private let appConfigProvider: AppConfigProvider

    var item: Item?

    init(wallet: Wallet, error: Error, walletManager: WalletManager, adapterManager: AdapterManager, appConfigProvider: AppConfigProvider, evmBlockchainManager: EvmBlockchainManager) {
        self.wallet = wallet
        self.error = error
        self.adapterManager = adapterManager
        self.appConfigProvider = appConfigProvider

        if wallet.token.blockchainType.coinSettingTypes(accountOrigin: wallet.account.origin).contains(.restoreSource) {
            let config = BtcBlockchainSettingsModule.Config(
                    blockchain: wallet.token.blockchain,
                    accountType: wallet.account.type,
                    accountOrigin: wallet.account.origin,
                    coinSettingsArray: walletManager.activeWallets.filter { $0.token.blockchainType == wallet.token.blockchainType }.map { $0.coinSettings },
                    mode: .changeSource(wallet: wallet)
            )
            item = .btc(config: config)
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
        case btc(config: BtcBlockchainSettingsModule.Config)
        case evm(blockchain: Blockchain)
    }

}

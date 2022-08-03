import Foundation
import MarketKit
import RxSwift

class WatchAddressBlockchainManager {
    private let disposeBag = DisposeBag()
    
    private let marketKit: MarketKit.Kit
    private let walletManager: WalletManager
    private let accountManager: AccountManager
    private let evmBlockchainManager: EvmBlockchainManager

    init(marketKit: MarketKit.Kit, walletManager: WalletManager, accountManager: AccountManager, evmBlockchainManager: EvmBlockchainManager) {
        self.marketKit = marketKit
        self.walletManager = walletManager
        self.accountManager = accountManager
        self.evmBlockchainManager = evmBlockchainManager

        subscribe(disposeBag, accountManager.activeAccountObservable) { [weak self] in
            self?.enableDisabledBlockchains(account: $0)
        }
        enableDisabledBlockchains(account: accountManager.activeAccount)
    }
}

extension WatchAddressBlockchainManager {
    func enableDisabledBlockchains(account: Account?) {
        guard let account = account, account.watchAccount else {
            return
        }

        let wallets = walletManager.wallets(account: account)
        let disabledBlockchains = evmBlockchainManager
            .allBlockchains
            .filter { blockchain in !wallets.contains(where: { wallet in wallet.token.blockchain == blockchain }) }

        guard !disabledBlockchains.isEmpty else {
            return
        }

        do {
            for blockchain in disabledBlockchains {
                evmBlockchainManager.evmAccountManager(blockchainType: blockchain.type).markAutoEnable(account: account)
            }

            let tokens = try marketKit.tokens(queries: disabledBlockchains.map { TokenQuery(blockchainType: $0.type, tokenType: .native) })
            let wallets = tokens.map { Wallet(token: $0, account: account) }

            walletManager.save(wallets: wallets)
        } catch {
            // do nothing
        }
    }
}

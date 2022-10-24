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

    private func enableEvmBlockchains(account: Account) {
        let wallets = walletManager.wallets(account: account)
        let disabledBlockchains = evmBlockchainManager
                .allBlockchains
                .filter { blockchain in !wallets.contains(where: { wallet in wallet.token.blockchain == blockchain }) }

        guard !disabledBlockchains.isEmpty else {
            return
        }

        do {
            let tokens = try marketKit.tokens(queries: disabledBlockchains.map { TokenQuery(blockchainType: $0.type, tokenType: .native) })
            let wallets = tokens.map { Wallet(token: $0, account: account) }

            walletManager.save(wallets: wallets)
        } catch {
            // do nothing
        }
    }

    private func enableBtcBlockchains(account: Account, mnemonicDerivation: MnemonicDerivation) {
        let blockchainTypes: [BlockchainType] = [.bitcoin, .bitcoinCash, .litecoin, .dash]
        let supportedBlockchainTypes = blockchainTypes.filter { $0.supports(accountType: account.type) }

        let wallets = walletManager.wallets(account: account)
        let disabledBlockchainTypes = supportedBlockchainTypes
                .filter { blockchainType in !wallets.contains(where: { wallet in wallet.token.blockchainType == blockchainType }) }

        guard !disabledBlockchainTypes.isEmpty else {
            return
        }

        do {
            let tokens = try marketKit.tokens(queries: disabledBlockchainTypes.map { TokenQuery(blockchainType: $0, tokenType: .native) })

            var wallets = [Wallet]()

            for token in tokens {
                if token.blockchainType.coinSettingType == .derivation {
                    let configuredToken = ConfiguredToken(token: token, coinSettings: [.derivation: mnemonicDerivation.rawValue])
                    let wallet = Wallet(configuredToken: configuredToken, account: account)
                    wallets.append(wallet)
                } else if token.blockchainType.coinSettingType == .bitcoinCashCoinType {
                    let _wallets = BitcoinCashCoinType.allCases.map { coinType -> Wallet in
                        let configuredToken = ConfiguredToken(token: token, coinSettings: [.bitcoinCashCoinType: coinType.rawValue])
                        return Wallet(configuredToken: configuredToken, account: account)
                    }

                    wallets.append(contentsOf: _wallets)
                } else {
                    let wallet = Wallet(token: token, account: account)
                    wallets.append(wallet)
                }
            }

            walletManager.save(wallets: wallets)
        } catch {
            // do nothing
        }
    }

}

extension WatchAddressBlockchainManager {

    func enableDisabledBlockchains(account: Account?) {
        guard let account = account else {
            return
        }

        switch account.type {
        case .evmAddress:
            enableEvmBlockchains(account: account)
        case let .hdExtendedKey(key):
            switch key {
            case .public:
                enableBtcBlockchains(account: account, mnemonicDerivation: key.info.purpose.mnemonicDerivation)
            default: ()
            }
        default:
            ()
        }
    }

}

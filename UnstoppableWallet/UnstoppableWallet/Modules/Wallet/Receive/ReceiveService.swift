import Foundation
import MarketKit
import Combine

class ReceiveService {
    private let account: Account
    private let walletManager: WalletManager
    private let marketKit: MarketKit.Kit

    private let showTokenSubject = PassthroughSubject<Wallet, Never>()
    private let showBlockchainSelectSubject = PassthroughSubject<(FullCoin, AccountType), Never>()
    private let showDerivationSelectSubject = PassthroughSubject<[Wallet], Never>()
    private let showBitcoinCashCoinTypeSelectSubject = PassthroughSubject<[Wallet], Never>()

    init(account: Account, walletManager: WalletManager, marketKit: MarketKit.Kit) {
        self.account = account
        self.walletManager = walletManager
        self.marketKit = marketKit
    }

    private func checkExists(token: Token) {
        // check if wallet already exist
        let wallets = walletManager
                .activeWallets
                .filter { wallet in wallet.token == token }

        switch wallets.count {
        case 0:                 // create wallet and show deposit
            let wallet = createWallet(token: token)
            showDeposit(wallet: wallet)
        case 1:                 // just show deposit. When unique token and it's restored
            showDeposit(wallet: wallets[0])
        default:                // show choose derivation, addressFormat or other (when token is unique, but many wallets)
            chooseExact(token: token, wallets: wallets)
        }
    }

    private func createWallet(token: Token) -> Wallet {
        let defaultSettings = token.blockchainType.defaultSettings(accountType: account.type)
        let configuredToken = ConfiguredToken(token: token, coinSettings: defaultSettings)
        let wallet = Wallet(configuredToken: configuredToken, account: account)

        walletManager.save(wallets: [wallet])
        return wallet
    }

    private func showDeposit(wallet: Wallet) {
        showTokenSubject.send(wallet)
    }

    private func chooseExact(token: Token, wallets: [Wallet]) {
        switch token.blockchainType {
        case .bitcoin, .litecoin:
            showDerivationSelectSubject.send(wallets)
        case .bitcoinCash:
            showBitcoinCashCoinTypeSelectSubject.send(wallets)
        case .zcash:
            ()
        default: // other blockchains can't have more than 1 wallet
            ()
        }
    }
}

extension ReceiveService {

    var showTokenPublisher: AnyPublisher<Wallet, Never> {
        showTokenSubject.eraseToAnyPublisher()
    }

    var showDerivationSelectPublisher: AnyPublisher<[Wallet], Never> {
        showDerivationSelectSubject.eraseToAnyPublisher()
    }

    var showBitcoinCashCoinTypeSelectPublisher: AnyPublisher<[Wallet], Never> {
        showBitcoinCashCoinTypeSelectSubject.eraseToAnyPublisher()
    }

    var showBlockchainSelectPublisher: AnyPublisher<(FullCoin, AccountType), Never> {
        showBlockchainSelectSubject.eraseToAnyPublisher()
    }

    func onSelect(fullCoin: FullCoin) {
        if fullCoin.tokens.count == 1 {
            checkExists(token: fullCoin.tokens[0])
        } else {
            showBlockchainSelectSubject.send((fullCoin, account.type))
        }
    }

    func onSelectExact(token: Token) {
        checkExists(token: token)
    }

}
extension ReceiveService {

    var predefinedCoins: [FullCoin] {
        guard let accountType = App.shared.accountManager.activeAccount?.type else {
            return []
        }

        // get all restored coins
        let activeWallets = walletManager.activeWallets
        let walletCoins = activeWallets.map {
            $0.coin
        }
        // get all native coins for supported blockchains
        let nativeCoins = CoinProvider.nativeCoins(marketKit: marketKit)
        let predefinedCoins = (walletCoins + nativeCoins).removeDuplicates()

        // found all full coins
        let fullCoins = try? marketKit.fullCoins(coinUids: predefinedCoins.map {
            $0.uid
        })

        // filter not supported by current account
        let predefined = fullCoins?.filter { coin in
            !coin.eligibleTokens(accountType: accountType).isEmpty
        } ?? []

        return predefined
    }

}

import Combine
import Foundation
import MarketKit

class ReceiveService {
    private let account: Account
    private let walletManager: WalletManager
    private let marketKit: MarketKit.Kit
    private let restoreSettingsService: RestoreSettingsService

    private let showTokenSubject = PassthroughSubject<Wallet, Never>()
    private let showBlockchainSelectSubject = PassthroughSubject<(FullCoin, AccountType), Never>()
    private let showDerivationSelectSubject = PassthroughSubject<[Wallet], Never>()
    private let showBitcoinCashCoinTypeSelectSubject = PassthroughSubject<[Wallet], Never>()
    private let showZcashRestoreSelectSubject = PassthroughSubject<Token, Never>()

    init(account: Account, walletManager: WalletManager, marketKit: MarketKit.Kit, restoreSettingsService: RestoreSettingsService) {
        self.account = account
        self.walletManager = walletManager
        self.marketKit = marketKit
        self.restoreSettingsService = restoreSettingsService
    }

    private func showReceive(token: Token) {
        // check if wallet already exist
        let wallet = walletManager
            .activeWallets
            .first { $0.token == token }

        if let wallet {
            showTokenSubject.send(wallet)
        } else {
            let wallet = createWallet(token: token)
            showTokenSubject.send(wallet)
        }
    }

    private func createWallet(token: Token) -> Wallet {
        let wallet = Wallet(token: token, account: account)

        walletManager.save(wallets: [wallet])
        return wallet
    }

    private func chooseTokenWithSettings(tokens: [Token]) {
        // all tokens will have same blockchain type
        guard let first = tokens.first else {
            return
        }

        // check if has existed wallets
        let wallets = walletManager
            .activeWallets
            .filter { wallet in tokens.contains(wallet.token) }

        switch wallets.count {
        case 0: // create wallet and show deposit
            switch first.blockchainType {
            case .bitcoin, .litecoin, .bitcoinCash:
                guard let defaultToken = try? marketKit.token(query: first.blockchainType.defaultTokenQuery) else {
                    return
                }

                let wallet = createWallet(token: defaultToken)
                showTokenSubject.send(wallet)
            case .zcash:
                showZcashRestoreSelectSubject.send(first) // we must enable zcash wallet and ask for birthday
            default: ()
            }
        case 1: // just show deposit. When unique token and it's restored
            showTokenSubject.send(wallets[0])
        default: // show choose derivation, addressFormat or other (when token is unique, but many wallets)
            chooseTokenType(blockchainType: first.blockchainType, wallets: wallets)
        }
    }

    private func chooseTokenType(blockchainType: BlockchainType, wallets: [Wallet]) {
        switch blockchainType {
        case .bitcoin, .litecoin:
            showDerivationSelectSubject.send(wallets)
        case .bitcoinCash:
            showBitcoinCashCoinTypeSelectSubject.send(wallets)
        default: // other blockchains can't have more than 1 wallet
            ()
        }
    }

    private func hasSettings(_ tokens: [Token]) -> Bool {
        tokens.allSatisfy { token in
            switch token.blockchainType {
            case .zcash: return true
            default: ()
            }
            switch token.type {
            case .derived, .addressType: return true
            default: return false
            }
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

    var showZcashRestoreSelectPublisher: AnyPublisher<Token, Never> {
        showZcashRestoreSelectSubject.eraseToAnyPublisher()
    }

    var showBlockchainSelectPublisher: AnyPublisher<(FullCoin, AccountType), Never> {
        showBlockchainSelectSubject.eraseToAnyPublisher()
    }

    func onSelect(fullCoin: FullCoin) {
        let eligibleTokens = fullCoin.tokens.filter { account.type.supports(token: $0) }

        let avoidSimpleShow = eligibleTokens.first { token in token.blockchainType == .zcash } != nil
        // For alone token check exists and show address
        if eligibleTokens.count == 1, !avoidSimpleShow {
            showReceive(token: eligibleTokens[0])
            return
        }
        // For multi tokens check hasSettings(derived and addressType)
        // if has, check exists wallets and show address or only exists tokens
        // Otherwise, show
        if hasSettings(eligibleTokens) {
            chooseTokenWithSettings(tokens: eligibleTokens)
        } else {
            showBlockchainSelectSubject.send((fullCoin, account.type))
        }
    }

    func onSelectExact(token: Token) {
        showReceive(token: token)
    }

    func onRestoreZcash(token: Token, height: Int?) {
        let tokenWithSettings = restoreSettingsService.enter(birthdayHeight: height, token: token)

        restoreSettingsService.save(settings: tokenWithSettings.settings, account: account, blockchainType: token.blockchainType)
        showReceive(token: token)
    }
}

extension ReceiveService {
    func isEnabled(coin: Coin) -> Bool {
        walletManager.activeWallets.contains { $0.coin == coin }
    }
}

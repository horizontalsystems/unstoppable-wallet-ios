import MarketKit
import SwiftUI
import UIKit

enum ReceiveModule {
    @ViewBuilder static func view(account: Account, fullCoin: FullCoin, path: Binding<NavigationPath>, onDismiss: (() -> Void)?) -> some View {
        let eligibleTokens = fullCoin.tokens.filter { account.type.supports(token: $0) }

        // For alone token check exists and show address
        if eligibleTokens.count == 1 {
            view(token: eligibleTokens[0], account: account, path: path, onDismiss: onDismiss)
        } else if hasSettings(eligibleTokens), eligibleTokens.count > 0 {
            viewWithSettings(account: account, tokens: eligibleTokens, path: path, onDismiss: onDismiss)
        } else {
            ReceiveBlockhainListView(account: account, fullCoin: fullCoin, path: path, onDismiss: onDismiss)
        }
    }

    @ViewBuilder private static func viewWithSettings(account: Account, tokens: [Token], path: Binding<NavigationPath>, onDismiss: (() -> Void)?) -> some View {
        // all tokens will have same blockchain type
        let first = tokens[0]

        // check if has existed wallets
        let wallets = Core.shared.walletManager
            .activeWallets
            .filter { wallet in tokens.contains(wallet.token) }

        switch wallets.count {
        // create wallet with default settings and show deposit
        case 0:
            switch first.blockchainType {
            case .bitcoin, .litecoin, .bitcoinCash:
                let defaultToken = (try? Core.shared.marketKit.token(query: first.blockchainType.defaultTokenQuery)) ?? first
                let wallet = createWallet(account: account, token: defaultToken)

                ReceiveAddressModule.instance(wallet: wallet, path: path, onDismiss: onDismiss)
            default: EmptyView()
            }

        // just show deposit. When unique token and it's restored
        case 1:
            ReceiveAddressModule.instance(wallet: wallets[0], path: path, onDismiss: onDismiss)

        // show choose derivation, addressFormat or other (when token is unique, but many wallets)
        default:
            switch first.blockchainType {
            case .bitcoin, .litecoin:
                let viewModel = ReceiveDerivationViewModel(wallets: wallets)
                ReceiveSettingsListView(viewModel: viewModel, path: path, onDismiss: onDismiss)
            case .bitcoinCash:
                let viewModel = ReceiveBitcoinCashCoinTypeViewModel(wallets: wallets)
                ReceiveSettingsListView(viewModel: viewModel, path: path, onDismiss: onDismiss)
            default:
                EmptyView()
            }
        }
    }

    @ViewBuilder static func view(token: Token, account: Account, path: Binding<NavigationPath>, onDismiss: (() -> Void)?) -> some View {
        let wallet = wallet(account: account, token: token)
        ReceiveAddressModule.instance(wallet: wallet, path: path, onDismiss: onDismiss)
    }

    private static func hasSettings(_ tokens: [Token]) -> Bool {
        tokens.allSatisfy { token in
            switch token.type {
            case .derived, .addressType: return true
            default: return false
            }
        }
    }

    static func isEnabled(token: Token) -> Bool {
        Core.shared.walletManager
            .activeWallets
            .first { $0.token == token } != nil
    }

    @discardableResult static func createWallet(account: Account, token: Token) -> Wallet {
        let wallet = Wallet(token: token, account: account)
        Core.shared.walletManager.save(wallets: [wallet])

        return wallet
    }

    private static func wallet(account: Account, token: Token) -> Wallet {
        let wallet = Core.shared.walletManager
            .activeWallets
            .first { $0.token == token }

        if let wallet {
            return wallet
        } else {
            let wallet = Wallet(token: token, account: account)
            Core.shared.walletManager.save(wallets: [wallet])

            return wallet
        }
    }
}

extension ReceiveModule {
    enum ReceiveError: Error {
        case noEligibleTokens
    }
}

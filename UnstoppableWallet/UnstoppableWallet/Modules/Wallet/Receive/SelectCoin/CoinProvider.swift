import Foundation
import MarketKit

class CoinProvider {
    private let marketKit: MarketKit.Kit
    private let walletManager: WalletManager
    private let accountType: AccountType

    var custom: [FullCoin] = []
    var predefined: [FullCoin] = []

    init(marketKit: MarketKit.Kit, walletManager: WalletManager, accountType: AccountType) {
        self.marketKit = marketKit
        self.walletManager = walletManager
        self.accountType = accountType

        custom = walletManager.activeWallets
            .filter { wallet in wallet.token.isCustom }
            .map { FullCoin(coin: $0.coin, tokens: [$0.token]) }

        predefined = predefinedCoins
    }

    private var nativeFullCoins: [FullCoin] {
        do {
            let blockchainTypes = BlockchainType.supported.sorted()
            let queries = blockchainTypes.map { $0.nativeTokenQueries }.flatMap { $0 }
            let coinUids = try marketKit
                .tokens(queries: queries)
                .map { $0.coin.uid }

            return try marketKit.fullCoins(coinUids: coinUids)
        } catch {
            return []
        }
    }

    private func customCoins(filter: String) -> [FullCoin] {
        custom.filter { fullCoin in
            fullCoin.coin.code.localizedCaseInsensitiveContains(filter) || fullCoin.coin.name.localizedCaseInsensitiveContains(filter)
        }
    }

}

extension CoinProvider {

    func fetch(filter: String) -> [FullCoin] {
        guard !filter.isEmpty else {
            return predefined
        }

        do {
            var fullCoins = try marketKit.fullCoins(filter: filter)
            fullCoins.append(contentsOf: customCoins(filter: filter))

            return fullCoins.filter { fullCoin in
                fullCoin.tokens.contains { accountType.supports(token: $0) }
            }
        } catch {
            return []
        }
    }

}

extension CoinProvider {

    var predefinedCoins: [FullCoin] {
        // get all restored coins
        let activeWallets = walletManager.activeWallets
        let walletCoins = activeWallets.map { $0.coin }

        // found account full coins
        var walletFullCoins = (try? marketKit.fullCoins(coinUids: walletCoins.map { $0.uid })) ?? []
        walletFullCoins.append(contentsOf: custom)

        // get all native coins for supported blockchains
        let nativeFullCoins = nativeFullCoins


        // filter not supported by current account
        let predefined = (walletFullCoins + nativeFullCoins).removeDuplicates()
            .filter { fullCoin in
            fullCoin.tokens.contains { accountType.supports(token: $0) }
        }

        return predefined
    }

}

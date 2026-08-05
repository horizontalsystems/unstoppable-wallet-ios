import Combine

import MarketKit

class CoinPageViewModel: ObservableObject {
    let coin: Coin
    let swapToken: Token?
    private let watchlistManager = Core.shared.watchlistManager

    @Published var isFavorite: Bool {
        didSet {
            if isFavorite {
                watchlistManager.add(coinUid: coin.uid)
                HudHelper.instance.show(banner: .addedToWatchlist)
            } else {
                watchlistManager.remove(coinUid: coin.uid)
                HudHelper.instance.show(banner: .removedFromWatchlist)
            }
        }
    }

    init(coin: Coin) {
        self.coin = coin
        swapToken = Self.swapToken(coin: coin)

        isFavorite = watchlistManager.isWatched(coinUid: coin.uid)
    }

    // wallet token with the largest balance, else an eligible representative (as in the picker's Top section)
    private static func swapToken(coin: Coin) -> Token? {
        guard let account = Core.shared.accountManager.activeAccount else {
            return nil
        }

        let walletManager = Core.shared.walletManager
        let adapterManager = Core.shared.adapterManager

        let walletTokens = walletManager.activeWallets.filter { $0.coin.uid == coin.uid }

        if !walletTokens.isEmpty {
            return walletTokens
                .map { wallet in (wallet.token, adapterManager.balanceAdapter(for: wallet)?.balanceData.available ?? 0) }
                .sorted { lhs, rhs in
                    if lhs.1 != rhs.1 {
                        return lhs.1 > rhs.1
                    }
                    if lhs.0.blockchainType.order != rhs.0.blockchainType.order {
                        return lhs.0.blockchainType.order < rhs.0.blockchainType.order
                    }
                    return lhs.0.type.order < rhs.0.type.order
                }
                .first?.0
        }

        let tokens = ((try? Core.shared.marketKit.fullCoins(coinUids: [coin.uid]).first?.tokens) ?? [])
            .filter { account.type.supports(token: $0) && BlockchainType.supported.contains($0.blockchainType) }

        return tokens.sorted(by: [.codeNativeFirst, .blockchainOrder, .badge], context: TokenSortContext()).first
    }
}

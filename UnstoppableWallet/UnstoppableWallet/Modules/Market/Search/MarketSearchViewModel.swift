import Combine
import Foundation
import MarketKit

class MarketSearchViewModel: ObservableObject {
    private let keyRecentCoinUids = "market-recent-coin-uids"

    private let marketKit = App.shared.marketKit
    private let userDefaultsStorage = App.shared.userDefaultsStorage

    @Published private(set) var state: State = .placeholder(recentFullCoins: [], popularFullCoins: [])
    @Published var searchText: String = "" {
        didSet {
            syncState()
        }
    }

    private var recentCoinUids: [String] {
        didSet {
            userDefaultsStorage.set(value: recentCoinUids.joined(separator: ","), for: keyRecentCoinUids)
        }
    }

    init() {
        let recentCoinsUidsRaw: String = userDefaultsStorage.value(for: keyRecentCoinUids) ?? ""
        recentCoinUids = recentCoinsUidsRaw.components(separatedBy: ",")

        syncState()
    }

    private func syncState() {
        if searchText.isEmpty {
            let recentMarketFullCoins = (try? marketKit.fullCoins(coinUids: recentCoinUids)) ?? []
            let recentFullCoins = recentCoinUids.compactMap { coinUid in recentMarketFullCoins.first { $0.coin.uid == coinUid } }

            let popularFullCoins = (try? marketKit.topFullCoins()) ?? []

            state = .placeholder(recentFullCoins: recentFullCoins, popularFullCoins: popularFullCoins)
        } else {
            state = .searchResults(fullCoins: (try? marketKit.fullCoins(filter: searchText)) ?? [])
        }
    }
}

extension MarketSearchViewModel {
    func handleOpen(coinUid: String) {
        var recentCoinUids = recentCoinUids

        if let index = recentCoinUids.firstIndex(of: coinUid) {
            recentCoinUids.remove(at: index)
        }

        recentCoinUids.insert(coinUid, at: 0)
        self.recentCoinUids = Array(recentCoinUids.prefix(5))
    }
}

extension MarketSearchViewModel {
    enum State {
        case placeholder(recentFullCoins: [FullCoin], popularFullCoins: [FullCoin])
        case searchResults(fullCoins: [FullCoin])
    }
}

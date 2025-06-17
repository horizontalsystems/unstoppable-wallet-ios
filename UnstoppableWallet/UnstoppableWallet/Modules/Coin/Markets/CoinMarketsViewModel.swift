import Combine
import Foundation
import HsExtensions
import MarketKit

class CoinMarketsViewModel: ObservableObject {
    private let coinUid: String
    private let marketKit = Core.shared.marketKit
    private let currency = Core.shared.currencyManager.baseCurrency
    private var tasks = Set<AnyTask>()

    private var tickers: [MarketTicker]?

    @Published private(set) var state: State = .loading

    @Published var verifiedFilter: VerifiedFilter = .all {
        didSet {
            DispatchQueue.global().async { [weak self] in
                self?.syncState()
            }

            stat(page: .coinMarkets, event: .switchFilterType(type: verifiedFilter.rawValue))
        }
    }

    @Published var marketTypeFilter: MarketTypeFilter = .all {
        didSet {
            DispatchQueue.global().async { [weak self] in
                self?.syncState()
            }

            stat(page: .coinMarkets, event: .switchFilterType(type: verifiedFilter.rawValue))
        }
    }

    init(coinUid: String) {
        self.coinUid = coinUid
    }

    private func syncTickers() {
        tasks = Set()

        if case .failed = state {
            state = .loading
        }

        Task { [weak self, marketKit, coinUid, currency] in
            do {
                let tickers = try await marketKit.marketTickers(coinUid: coinUid, currencyCode: currency.code)
                self?.tickers = tickers
                self?.syncState()
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.state = .failed(error: error.smartDescription)
                }
            }
        }.store(in: &tasks)
    }

    private func syncState() {
        guard let tickers else {
            return
        }

        let filteredTickers = tickers.filter { ticker in
            let satisfyVerified = verifiedFilter == .all ? true : ticker.verified

            let satisfyMarketType: Bool
            switch marketTypeFilter {
            case .all:
                satisfyMarketType = true
            case .cex:
                satisfyMarketType = ticker.centralized
            case .dex:
                satisfyMarketType = !ticker.centralized
            }

            return satisfyVerified && satisfyMarketType
        }

        let sortedTickers = filteredTickers.sorted { $0.fiatVolume > $1.fiatVolume }
        let viewItems = sortedTickers.map { viewItem(ticker: $0) }

        DispatchQueue.main.async { [weak self] in
            self?.state = .loaded(viewItems: viewItems)
        }
    }

    private func viewItem(ticker: MarketTicker) -> ViewItem {
        ViewItem(
            market: ticker.marketName,
            marketImageUrl: ticker.marketImageUrl,
            pair: "\(ticker.base) / \(ticker.target)",
            volume: ValueFormatter.instance.formatShort(value: ticker.volume, decimalCount: 8, symbol: ticker.base),
            fiatVolume: ValueFormatter.instance.formatShort(currency: currency, value: ticker.fiatVolume),
            tradeUrl: ticker.tradeUrl,
            verified: ticker.verified
        )
    }
}

extension CoinMarketsViewModel {
    var marketTypeFilters: [MarketTypeFilter] {
        MarketTypeFilter.allCases
    }

    var verifiedFilterActivated: Bool {
        verifiedFilter == .verified
    }

    func load() {
        syncTickers()
    }

    func onRetry() {
        syncTickers()
    }

    func switchFilterType() {
        let allCases = VerifiedFilter.allCases
        let currentIndex = allCases.firstIndex(of: verifiedFilter) ?? 0
        let newIndex = (currentIndex + 1) % allCases.count
        verifiedFilter = allCases[newIndex]
    }
}

extension CoinMarketsViewModel {
    enum State {
        case loading
        case loaded(viewItems: [ViewItem])
        case failed(error: String)
    }

    enum VerifiedFilter: String, CaseIterable {
        case all
        case verified

        var title: String {
            "coin_markets.filter.verified".localized
        }
    }

    enum MarketTypeFilter: String, CaseIterable {
        case all
        case cex
        case dex

        var title: String {
            switch self {
            case .all: return "coin_markets.filter.all".localized
            case .cex: return "coin_markets.filter.cex".localized
            case .dex: return "coin_markets.filter.dex".localized
            }
        }
    }

    struct ViewItem: Hashable {
        let market: String
        let marketImageUrl: String?
        let pair: String
        let volume: String?
        let fiatVolume: String?
        let tradeUrl: String?
        let verified: Bool

        func hash(into hasher: inout Hasher) {
            hasher.combine(market)
            hasher.combine(pair)
        }
    }
}

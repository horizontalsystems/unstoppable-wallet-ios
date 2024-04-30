import Combine
import Foundation
import HsExtensions
import MarketKit

class CoinMarketsViewModel: ObservableObject {
    private let coin: Coin
    private let marketKit = App.shared.marketKit
    private let currency = App.shared.currencyManager.baseCurrency
    private var tasks = Set<AnyTask>()

    private var tickers: [MarketTicker]?

    @Published private(set) var state: State = .loading

    private var filterType: FilterType = .all {
        didSet {
            syncFilterTypeInfo()

            DispatchQueue.global().async { [weak self] in
                self?.syncState()
            }

            stat(page: .coinMarkets, event: .switchFilterType(type: filterType.rawValue))
        }
    }

    @Published var filterTypeInfo = SelectorButtonInfo(text: "", count: 0, selectedIndex: 0)

    init(coin: Coin) {
        self.coin = coin

        syncFilterTypeInfo()
    }

    private func syncTickers() {
        tasks = Set()

        if case .failed = state {
            state = .loading
        }

        Task { [weak self, marketKit, coin, currency] in
            do {
                let tickers = try await marketKit.marketTickers(coinUid: coin.uid, currencyCode: currency.code)
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

        let filteredTickers: [MarketTicker]

        switch filterType {
        case .all:
            filteredTickers = tickers
        case .verified:
            filteredTickers = tickers.filter(\.verified)
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

    private func syncFilterTypeInfo() {
        let text: String

        switch filterType {
        case .all: text = "coin_markets.filter.all".localized
        case .verified: text = "coin_markets.filter.verified".localized
        }

        filterTypeInfo = SelectorButtonInfo(text: text, count: FilterType.allCases.count, selectedIndex: FilterType.allCases.firstIndex(of: filterType) ?? 0)
    }
}

extension CoinMarketsViewModel {
    func onFirstAppear() {
        syncTickers()
    }

    func onRetry() {
        syncTickers()
    }

    func switchFilterType() {
        let allCases = FilterType.allCases
        let currentIndex = allCases.firstIndex(of: filterType) ?? 0
        let newIndex = (currentIndex + 1) % allCases.count
        filterType = allCases[newIndex]
    }
}

extension CoinMarketsViewModel {
    enum State {
        case loading
        case loaded(viewItems: [ViewItem])
        case failed(error: String)
    }

    private enum FilterType: String, CaseIterable {
        case all
        case verified
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

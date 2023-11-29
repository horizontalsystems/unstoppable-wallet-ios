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
        }
    }

    private var volumeType: VolumeType = .coin {
        didSet {
            syncVolumeTypeInfo()

            DispatchQueue.global().async { [weak self] in
                self?.syncState()
            }
        }
    }

    @Published var filterTypeInfo = SelectorButtonInfo(text: "", count: 0, selectedIndex: 0)
    @Published var volumeTypeInfo = SelectorButtonInfo(text: "", count: 0, selectedIndex: 0)

    init(coin: Coin) {
        self.coin = coin

        syncVolumeTypeInfo()
        syncFilterTypeInfo()
    }

    private func syncTickers() {
        tasks = Set()

        if case .failed = state {
            state = .loading
        }

        Task { [weak self, marketKit, coin] in
            do {
                let tickers = try await marketKit.marketTickers(coinUid: coin.uid)
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

        let sortedTickers = filteredTickers.sorted { $0.volume > $1.volume }
        let price = marketKit.coinPrice(coinUid: coin.uid, currencyCode: currency.code)?.value
        let viewItems = sortedTickers.map { viewItem(ticker: $0, price: price) }

        DispatchQueue.main.async { [weak self] in
            self?.state = .loaded(viewItems: viewItems)
        }
    }

    private func viewItem(ticker: MarketTicker, price: Decimal?) -> ViewItem {
        ViewItem(
            market: ticker.marketName,
            marketImageUrl: ticker.marketImageUrl,
            pair: "\(coin.code) / \(ticker.target)",
            rate: ValueFormatter.instance.formatShort(value: ticker.rate, decimalCount: 8, symbol: ticker.target),
            volume: volume(value: ticker.volume, price: price),
            tradeUrl: ticker.tradeUrl,
            verified: ticker.verified
        )
    }

    private func volume(value: Decimal, price: Decimal?) -> String? {
        switch volumeType {
        case .coin:
            return ValueFormatter.instance.formatShort(value: value, decimalCount: 8, symbol: coin.code)
        case .currency:
            guard let price else {
                return "n/a".localized
            }
            return ValueFormatter.instance.formatShort(currency: currency, value: value * price)
        }
    }

    private func syncFilterTypeInfo() {
        let text: String

        switch filterType {
        case .all: text = "coin_markets.filter.all".localized
        case .verified: text = "coin_markets.filter.verified".localized
        }

        filterTypeInfo = SelectorButtonInfo(text: text, count: FilterType.allCases.count, selectedIndex: FilterType.allCases.firstIndex(of: filterType) ?? 0)
    }

    private func syncVolumeTypeInfo() {
        let text: String

        switch volumeType {
        case .coin: text = coin.code
        case .currency: text = currency.code
        }

        volumeTypeInfo = SelectorButtonInfo(text: text, count: VolumeType.allCases.count, selectedIndex: VolumeType.allCases.firstIndex(of: volumeType) ?? 0)
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

    func switchVolumeType() {
        let allCases = VolumeType.allCases
        let currentIndex = allCases.firstIndex(of: volumeType) ?? 0
        let newIndex = (currentIndex + 1) % allCases.count
        volumeType = allCases[newIndex]
    }
}

extension CoinMarketsViewModel {
    enum State {
        case loading
        case loaded(viewItems: [ViewItem])
        case failed(error: String)
    }

    private enum FilterType: CaseIterable {
        case all
        case verified
    }

    private enum VolumeType: CaseIterable {
        case coin
        case currency
    }

    struct ViewItem: Hashable {
        let market: String
        let marketImageUrl: String?
        let pair: String
        let rate: String?
        let volume: String?
        let tradeUrl: String?
        let verified: Bool

        func hash(into hasher: inout Hasher) {
            hasher.combine(market)
            hasher.combine(pair)
        }
    }
}

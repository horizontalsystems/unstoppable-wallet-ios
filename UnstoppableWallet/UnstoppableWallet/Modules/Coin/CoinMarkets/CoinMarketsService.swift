import Foundation
import XRatesKit
import CoinKit
import RxSwift
import RxRelay
import CurrencyKit

class CoinMarketsService {
    let coinCode: String
    private let coinType: CoinType
    let currency: Currency
    private let rate: Decimal
    private let tickers: [MarketTicker]

    private let sortTypeRelay = PublishRelay<SortType>()
    private(set) var sortType: SortType = .highestVolume {
        didSet {
            sortTypeRelay.accept(sortType)
        }
    }

    private let volumeTypeRelay = PublishRelay<VolumeType>()
    private(set) var volumeType: VolumeType = .coin {
        didSet {
            volumeTypeRelay.accept(volumeType)
        }
    }

    private let itemsRelay = PublishRelay<[Item]>()
    private(set) var items: [Item] = [] {
        didSet {
            itemsRelay.accept(items)
        }
    }

    init(coinCode: String, coinType: CoinType, currencyKit: CurrencyKit.Kit, rateManager: IRateManager, tickers: [MarketTicker]) {
        self.coinCode = coinCode
        self.coinType = coinType
        currency = currencyKit.baseCurrency
        rate = rateManager.latestRate(coinType: coinType, currencyCode: currency.code)?.rate ?? 0
        self.tickers = tickers

        syncItems()
    }

    private func sortedTickers() -> [MarketTicker] {
        switch sortType {
        case .highestVolume: return tickers.sorted { $0.volume > $1.volume }
        case .lowestVolume: return tickers.sorted { $0.volume < $1.volume }
        }
    }

    private func volume(tickerVolume: Decimal) -> Decimal {
        switch volumeType {
        case .coin: return tickerVolume
        case .currency: return tickerVolume * rate
        }
    }

    private func syncItems() {
        items = sortedTickers().map { ticker in
            Item(
                    market: ticker.marketName,
                    marketImageUrl: ticker.marketImageUrl,
                    targetCoinCode: ticker.target,
                    rate: ticker.rate,
                    volume: volume(tickerVolume: ticker.volume),
                    volumeType: volumeType
            )
        }
    }

}

extension CoinMarketsService {

    var sortTypeObservable: Observable<SortType> {
        sortTypeRelay.asObservable()
    }

    var volumeTypeObservable: Observable<VolumeType> {
        volumeTypeRelay.asObservable()
    }

    var itemsObservable: Observable<[Item]> {
        itemsRelay.asObservable()
    }

    func set(sortType: SortType) {
        self.sortType = sortType
        syncItems()
    }

    func set(volumeType: VolumeType) {
        self.volumeType = volumeType
        syncItems()
    }

}

extension CoinMarketsService {

    struct Item {
        let market: String
        let marketImageUrl: String?
        let targetCoinCode: String
        let rate: Decimal
        let volume: Decimal
        let volumeType: VolumeType
    }

    enum SortType: CaseIterable {
        case highestVolume
        case lowestVolume
    }

    enum VolumeType: CaseIterable {
        case coin
        case currency
    }

}

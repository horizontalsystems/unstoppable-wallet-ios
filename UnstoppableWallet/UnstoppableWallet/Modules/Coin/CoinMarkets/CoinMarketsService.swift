import Foundation
import MarketKit
import RxSwift
import RxRelay
import CurrencyKit

class CoinMarketsService {
    private let disposeBag = DisposeBag()
    private let marketKit: MarketKit.Kit

    private let price: Decimal
    private var tickers = [MarketTicker]()

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

    let fullCoin: FullCoin
    let currency: Currency

    var coinCode: String {
        fullCoin.coin.code
    }

    init(fullCoin: FullCoin, currencyKit: CurrencyKit.Kit, marketKit: MarketKit.Kit) {
        self.fullCoin = fullCoin
        currency = currencyKit.baseCurrency
        self.marketKit = marketKit
        price = marketKit.coinPrice(coinUid: fullCoin.coin.uid, currencyCode: currency.code)?.value ?? 0
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
        case .currency: return tickerVolume * price
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

    func fetch() {
        marketKit.marketTickersSingle(coinUid: fullCoin.coin.uid)
                .subscribe(onSuccess: { [weak self] tickers in
                    self?.tickers = tickers
                    self?.syncItems()
                })
                .disposed(by: disposeBag)
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

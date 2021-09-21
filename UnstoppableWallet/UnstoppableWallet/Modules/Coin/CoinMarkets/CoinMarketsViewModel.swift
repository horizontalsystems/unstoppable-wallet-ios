import Foundation
import RxSwift
import RxRelay
import RxCocoa

class CoinMarketsViewModel {
    private let service: CoinMarketsService
    private let disposeBag = DisposeBag()

    private let sortDescendingRelay = BehaviorRelay<Bool>(value: true)
    private let viewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])

    init(service: CoinMarketsService) {
        self.service = service

        subscribe(disposeBag, service.sortTypeObservable) { [weak self] in self?.sync(sortType: $0) }
        subscribe(disposeBag, service.itemsObservable) { [weak self] in self?.sync(items: $0) }

        sync(sortType: service.sortType)
        sync(items: service.items)
    }

    private func sync(sortType: CoinMarketsService.SortType) {
        sortDescendingRelay.accept(sortType == .highestVolume)
    }

    private func sync(items: [CoinMarketsService.Item]) {
        viewItemsRelay.accept(items.map { viewItem(item: $0) })
    }

    private func viewItem(item: CoinMarketsService.Item) -> ViewItem {
        ViewItem(
                market: item.market,
                marketImageUrl: item.marketImageUrl,
                pair: "\(service.coinCode) / \(item.targetCoinCode)",
                rate: ValueFormatter.instance.format(value: item.rate, decimalCount: 8, symbol: item.targetCoinCode, fractionPolicy: .threshold(high: 0.01, low: 0)),
                volume: volume(value: item.volume, type: item.volumeType)
        )
    }

    private func volume(value: Decimal, type: CoinMarketsService.VolumeType) -> String? {
        switch type {
        case .coin: return CurrencyCompactFormatter.instance.format(symbol: service.coinCode, value: value)
        case .currency: return CurrencyCompactFormatter.instance.format(currency: service.currency, value: value)
        }
    }

    private func value(volumeType: CoinMarketsService.VolumeType) -> String {
        switch volumeType {
        case .coin: return service.coinCode
        case .currency: return service.currency.code
        }
    }

    private func title(sortType: CoinMarketsService.SortType) -> String {
        switch sortType {
        case .highestVolume: return "coin_page.coin_markets.sort_by.highest_volume".localized
        case .lowestVolume: return "coin_page.coin_markets.sort_by.lowest_volume".localized
        }
    }

}

extension CoinMarketsViewModel {

    var title: String {
        "coin_page.coin_markets".localized(service.coinCode)
    }

    var sortDescendingDriver: Driver<Bool> {
        sortDescendingRelay.asDriver()
    }

    var viewItemsDriver: Driver<[ViewItem]> {
        viewItemsRelay.asDriver()
    }

    var volumeTypes: [String] {
        CoinMarketsService.VolumeType.allCases.map { value(volumeType: $0) }
    }

    func onSwitchSortType() {
        service.set(sortType: service.sortType == .highestVolume ? .lowestVolume : .highestVolume)
    }

    func onSelectVolumeType(index: Int) {
        service.set(volumeType: CoinMarketsService.VolumeType.allCases[index])
    }

}

extension CoinMarketsViewModel {

    struct ViewItem {
        let market: String
        let marketImageUrl: String?
        let pair: String
        let rate: String?
        let volume: String?
    }

}

import RxSwift
import RxRelay
import RxCocoa
import CurrencyKit
import MarketKit

protocol IMarketListService {
    var currency: Currency { get }
    var state: MarketListServiceState { get }
    var stateObservable: Observable<MarketListServiceState> { get }
    var sortingField: MarketModule.SortingField { get }
    var sortingFieldObservable: Observable<MarketModule.SortingField> { get }
    var marketField: MarketModule.MarketField { get }
    var marketFieldObservable: Observable<MarketModule.MarketField> { get }
    func refresh()
}

enum MarketListServiceState {
    case loading
    case loaded(marketInfos: [MarketInfo])
    case failed(error: Error)
}

class MarketListViewModel {
    private let service: IMarketListService
    private let disposeBag = DisposeBag()

    private let viewItemsRelay = BehaviorRelay<[ViewItem]?>(value: nil)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = BehaviorRelay<String?>(value: nil)

    init(service: IMarketListService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
        subscribe(disposeBag, service.sortingFieldObservable) { [weak self] _ in self?.syncViewItemsIfPossible() }
        subscribe(disposeBag, service.marketFieldObservable) { [weak self] _ in self?.syncViewItemsIfPossible() }

        sync(state: service.state)
    }

    private func sync(state: MarketListServiceState) {
        switch state {
        case .loading:
            viewItemsRelay.accept(nil)
            loadingRelay.accept(true)
            errorRelay.accept(nil)
        case .loaded(let marketInfos):
            viewItemsRelay.accept(viewItems(marketInfos: marketInfos))
            loadingRelay.accept(false)
            errorRelay.accept(nil)
        case .failed:
            viewItemsRelay.accept(nil)
            loadingRelay.accept(false)
            errorRelay.accept("market.sync_error".localized)
        }
    }

    private func syncViewItemsIfPossible() {
        guard case .loaded(let marketInfos) = service.state else {
            return
        }

        viewItemsRelay.accept(viewItems(marketInfos: marketInfos))
    }

    private func viewItems(marketInfos: [MarketInfo]) -> [ViewItem] {
        sorted(marketInfos: marketInfos, sortingField: service.sortingField).map {
            viewItem(marketInfo: $0, marketField: service.marketField, currency: service.currency)
        }
    }

    private func viewItem(marketInfo: MarketInfo, marketField: MarketModule.MarketField, currency: Currency) -> ViewItem {
        let priceCurrencyValue = CurrencyValue(currency: currency, value: marketInfo.price)
        let dataValue: DataValue

        switch marketField {
        case .price: dataValue = .diff(marketInfo.priceChange)
        case .volume: dataValue = .volume(CurrencyCompactFormatter.instance.format(currency: currency, value: marketInfo.totalVolume) ?? "-")
        case .marketCap: dataValue = .marketCap(CurrencyCompactFormatter.instance.format(currency: currency, value: marketInfo.marketCap) ?? "-")
        }

        return ViewItem(
                uid: marketInfo.coin.uid,
                iconUrl: marketInfo.coin.imageUrl,
                name: marketInfo.coin.name,
                code: marketInfo.coin.code,
                rank: marketInfo.coin.marketCapRank.map { "\($0)" },
                price: ValueFormatter.instance.format(currencyValue: priceCurrencyValue, fractionPolicy: .threshold(high: 1000, low: 0.000001), trimmable: false) ?? "",
                dataValue: dataValue
        )
    }

    func sorted(marketInfos: [MarketInfo], sortingField: MarketModule.SortingField) -> [MarketInfo] {
        marketInfos.sorted { lhsMarketInfo, rhsMarketInfo in
            switch sortingField {
            case .highestCap: return lhsMarketInfo.marketCap > rhsMarketInfo.marketCap
            case .lowestCap: return lhsMarketInfo.marketCap < rhsMarketInfo.marketCap
            case .highestVolume: return lhsMarketInfo.totalVolume > rhsMarketInfo.totalVolume
            case .lowestVolume: return lhsMarketInfo.totalVolume < rhsMarketInfo.totalVolume
            case .topGainers, .topLosers:
                guard let rhsPriceChange = rhsMarketInfo.priceChange else {
                    return true
                }
                guard let lhsPriceChange = lhsMarketInfo.priceChange else {
                    return false
                }

                return sortingField == .topGainers ? lhsPriceChange > rhsPriceChange : lhsPriceChange < rhsPriceChange
            }
        }
    }

}

extension MarketListViewModel {

    var viewItemsDriver: Driver<[ViewItem]?> {
        viewItemsRelay.asDriver()
    }

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var errorDriver: Driver<String?> {
        errorRelay.asDriver()
    }

    func refresh() {
        service.refresh()
    }

}

extension MarketListViewModel {

    struct ViewItem {
        let uid: String
        let iconUrl: String
        let name: String
        let code: String
        let rank: String?
        let price: String
        let dataValue: DataValue
    }

    enum DataValue {
        case diff(Decimal?)
        case volume(String)
        case marketCap(String)
    }

}

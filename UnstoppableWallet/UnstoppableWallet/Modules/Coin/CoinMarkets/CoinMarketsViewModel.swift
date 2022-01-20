import Foundation
import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class CoinMarketsViewModel {
    private let service: CoinMarketsService
    private let disposeBag = DisposeBag()

    private let viewItemsRelay = BehaviorRelay<[ViewItem]?>(value: nil)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let infoRelay = BehaviorRelay<String?>(value: nil)
    private let errorRelay = BehaviorRelay<String?>(value: nil)
    private let scrollToTopRelay = PublishRelay<()>()

    private var volumeType: VolumeType = .coin {
        didSet {
            syncViewItemsIfPossible()
        }
    }

    init(service: CoinMarketsService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
    }

    private func sync(state: CoinMarketsService.State) {
        switch state {
        case .loading:
            viewItemsRelay.accept(nil)
            loadingRelay.accept(true)
            infoRelay.accept(nil)
            errorRelay.accept(nil)
        case .loaded(let tickers, let reorder):
            viewItemsRelay.accept(viewItems(tickers: tickers))
            loadingRelay.accept(false)
            infoRelay.accept(tickers.isEmpty ? "coin_page.markets.empty".localized : nil)
            errorRelay.accept(nil)

            if reorder {
                scrollToTopRelay.accept(())
            }
        case .failed:
            viewItemsRelay.accept(nil)
            loadingRelay.accept(false)
            infoRelay.accept(nil)
            errorRelay.accept("market.sync_error".localized)
        }
    }

    private func syncViewItemsIfPossible() {
        guard case .loaded(let tickers, _) = service.state else {
            return
        }

        viewItemsRelay.accept(viewItems(tickers: tickers))
    }

    private func viewItems(tickers: [MarketTicker]) -> [ViewItem] {
        let price = service.price
        return tickers.map { viewItem(ticker: $0, price: price) }
    }

    private func viewItem(ticker: MarketTicker, price: Decimal?) -> ViewItem {
        ViewItem(
                market: ticker.marketName,
                marketImageUrl: ticker.marketImageUrl,
                pair: "\(service.coinCode) / \(ticker.target)",
                rate: ValueFormatter.instance.format(value: ticker.rate, decimalCount: 8, symbol: ticker.target, fractionPolicy: .threshold(high: 0.01, low: 0)),
                volume: volume(value: ticker.volume, price: price)
        )
    }

    private func volume(value: Decimal, price: Decimal?) -> String? {
        switch volumeType {
        case .coin:
            return CurrencyCompactFormatter.instance.format(symbol: service.coinCode, value: value)
        case .currency:
            guard let price = price else {
                return "n/a".localized
            }
            return CurrencyCompactFormatter.instance.format(currency: service.currency, value: value * price)
        }
    }

    private func title(volumeType: VolumeType) -> String {
        switch volumeType {
        case .coin: return service.coinCode
        case .currency: return service.currency.code
        }
    }

}

extension CoinMarketsViewModel: IMarketSingleSortHeaderDecorator {

    var allFields: [String] {
        VolumeType.allCases.map { title(volumeType: $0) }
    }

    var currentFieldIndex: Int {
        VolumeType.allCases.firstIndex(of: volumeType) ?? 0
    }

    var scrollToTopSignal: Signal<()> {
        scrollToTopRelay.asSignal()
    }

    func setCurrentField(index: Int) {
        volumeType = VolumeType.allCases[index]
    }

}

extension CoinMarketsViewModel {

    var viewItemsDriver: Driver<[ViewItem]?> {
        viewItemsRelay.asDriver()
    }

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var infoDriver: Driver<String?> {
        infoRelay.asDriver()
    }

    var errorDriver: Driver<String?> {
        errorRelay.asDriver()
    }

    func onLoad() {
        service.sync()
    }

    func onRefresh() {
        service.sync()
    }

}

extension CoinMarketsViewModel {

    enum VolumeType: CaseIterable {
        case coin
        case currency
    }

    struct ViewItem {
        let market: String
        let marketImageUrl: String?
        let pair: String
        let rate: String?
        let volume: String?
    }

}

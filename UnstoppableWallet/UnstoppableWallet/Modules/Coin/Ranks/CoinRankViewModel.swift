import Foundation
import RxSwift
import RxRelay
import RxCocoa
import MarketKit
import CurrencyKit

class CoinRankViewModel {
    private let timePeriods: [HsTimePeriod] = [.day1, .week1, .month1]

    private let service: CoinRankService
    private let disposeBag = DisposeBag()

    private let viewItemsRelay = BehaviorRelay<[ViewItem]?>(value: nil)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let syncErrorRelay = BehaviorRelay<Bool>(value: false)
    private let scrollToTopRelay = PublishRelay<()>()

    init(service: CoinRankService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
    }

    private func sync(state: CoinRankService.State) {
        switch state {
        case .loading:
            viewItemsRelay.accept(nil)
            loadingRelay.accept(true)
            syncErrorRelay.accept(false)
        case .loaded(let items, let reorder):
            viewItemsRelay.accept(viewItems(items: items))
            loadingRelay.accept(false)
            syncErrorRelay.accept(false)

            if reorder {
                scrollToTopRelay.accept(())
            }
        case .failed:
            viewItemsRelay.accept(nil)
            loadingRelay.accept(false)
            syncErrorRelay.accept(true)
        }
    }

    private func viewItems(items: [CoinRankService.Item]) -> [ViewItem] {
        let currency = service.currency
        return items.enumerated().map { index, item in
            viewItem(index: index, item: item, currency: currency)
        }
    }

    private func viewItem(index: Int, item: CoinRankService.Item, currency: Currency) -> ViewItem {
        ViewItem(
                uid: item.coin.uid,
                rank: "\(index + 1)",
                imageUrl: item.coin.imageUrl,
                code: item.coin.code,
                name: item.coin.name,
                value: formatted(value: item.value, currency: currency)
        )
    }

    private func formatted(value: Decimal, currency: Currency) -> String? {
        switch service.type {
        case .cexVolume, .dexVolume, .dexLiquidity, .revenue:
            return ValueFormatter.instance.formatShort(currencyValue: CurrencyValue(currency: currency, value: value))
        case .address, .txCount:
            return ValueFormatter.instance.formatShort(value: value)
        }
    }

}

extension CoinRankViewModel {

    var viewItemsDriver: Driver<[ViewItem]?> {
        viewItemsRelay.asDriver()
    }

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var syncErrorDriver: Driver<Bool> {
        syncErrorRelay.asDriver()
    }

    var scrollToTopSignal: Signal<()> {
        scrollToTopRelay.asSignal()
    }

    var title: String {
        switch service.type {
        case .cexVolume: return "coin_analytics.cex_volume_rank".localized
        case .dexVolume: return "coin_analytics.dex_volume_rank".localized
        case .dexLiquidity: return "coin_analytics.dex_liquidity_rank".localized
        case .address: return "coin_analytics.active_addresses_rank".localized
        case .txCount: return "coin_analytics.transaction_count_rank".localized
        case .revenue: return "coin_analytics.project_revenue_rank".localized
        }
    }

    var headerVisible: Bool {
        switch service.type {
        case .cexVolume, .dexVolume, .address, .txCount, .revenue: return true
        case .dexLiquidity: return false
        }
    }

    var selectorItems: [String] {
        timePeriods.map { $0.title }
    }

    var selectorIndex: Int {
        timePeriods.firstIndex(of: service.timePeriod) ?? 0
    }

    func onSelectSelector(index: Int) {
        service.timePeriod = timePeriods[index]
    }

    func onTapRetry() {
        service.sync()
    }

}

extension CoinRankViewModel {

    struct ViewItem {
        let uid: String
        let rank: String
        let imageUrl: String
        let code: String
        let name: String
        let value: String?
    }

}

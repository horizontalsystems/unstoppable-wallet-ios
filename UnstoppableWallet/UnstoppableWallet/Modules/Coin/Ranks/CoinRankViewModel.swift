import Foundation
import Combine
import RxSwift
import RxRelay
import RxCocoa
import MarketKit
import CurrencyKit

class CoinRankViewModel {
    private let timePeriods: [HsTimePeriod] = [.day1, .week1, .month1]

    private let service: CoinRankService
    private var cancellables = Set<AnyCancellable>()

    private let viewItemsRelay = BehaviorRelay<[ViewItem]?>(value: nil)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let syncErrorRelay = BehaviorRelay<Bool>(value: false)
    private let sortDirectionRelay: BehaviorRelay<Bool>
    private let scrollToTopRelay = PublishRelay<()>()

    init(service: CoinRankService) {
        self.service = service
        sortDirectionRelay = BehaviorRelay(value: service.sortDirectionAscending)

        service.$state
                .sink { [weak self] in self?.sync(state: $0) }
                .store(in: &cancellables)

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

    private func viewItems(items: [CoinRankService.IndexedItem]) -> [ViewItem] {
        let currency = service.currency
        return items.enumerated().map { index, item in
            viewItem(index: index, item: item, currency: currency)
        }
    }

    private func viewItem(index: Int, item: CoinRankService.IndexedItem, currency: Currency) -> ViewItem {
        ViewItem(
                uid: item.coin.uid,
                rank: "\(item.index)",
                imageUrl: item.coin.imageUrl,
                code: item.coin.code,
                name: item.coin.name,
                value: formatted(value: item.value, currency: currency)
        )
    }

    private func formatted(value: Decimal, currency: Currency) -> String? {
        switch service.type {
        case .cexVolume, .dexVolume, .dexLiquidity, .fee, .revenue:
            return ValueFormatter.instance.formatShort(currencyValue: CurrencyValue(currency: currency, value: value))
        case .address, .txCount, .holders:
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
        case .holders: return "coin_analytics.holders_rank".localized
        case .fee: return "coin_analytics.project_fee_rank".localized
        case .revenue: return "coin_analytics.project_revenue_rank".localized
        }
    }

    var description: String {
        switch service.type {
        case .cexVolume: return "coin_analytics.cex_volume_rank.description".localized
        case .dexVolume: return "coin_analytics.dex_volume_rank.description".localized
        case .dexLiquidity: return "coin_analytics.dex_liquidity_rank.description".localized
        case .address: return "coin_analytics.active_addresses_rank.description".localized
        case .txCount: return "coin_analytics.transaction_count_rank.description".localized
        case .holders: return "coin_analytics.holders_rank.description".localized
        case .fee: return "coin_analytics.project_fee_rank.description".localized
        case .revenue: return "coin_analytics.project_revenue_rank.description".localized
        }
    }

    var imageUid: String {
        switch service.type {
        case .cexVolume: return "cex_volume"
        case .dexVolume: return "dex_volume"
        case .dexLiquidity: return "dex_liquidity"
        case .address: return "active_addresses"
        case .txCount: return "trx_count"
        case .holders: return "holders"
        case .fee: return "fee"
        case .revenue: return "revenue"
        }
    }

    var sortDirectionDriver: Driver<Bool> {
        sortDirectionRelay.asDriver()
    }

    func onToggleSortDirection() {
        service.sortDirectionAscending = !service.sortDirectionAscending
        sortDirectionRelay.accept(service.sortDirectionAscending)
    }

    var selectorItems: [String]? {
        switch service.type {
        case .cexVolume, .dexVolume, .address, .txCount, .fee, .revenue: return timePeriods.map { $0.title }
        case .dexLiquidity, .holders: return nil
        }
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

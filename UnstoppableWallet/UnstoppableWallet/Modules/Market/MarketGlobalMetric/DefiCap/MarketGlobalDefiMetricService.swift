import Combine
import RxSwift
import RxRelay
import MarketKit
import CurrencyKit
import HsExtensions

class MarketGlobalDefiMetricService: IMarketSingleSortHeaderService {
    typealias Item = DefiItem

    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let disposeBag = DisposeBag()
    private var tasks = Set<AnyTask>()

    @PostPublished private(set) var state: MarketListServiceState<DefiItem> = .loading

    var sortDirectionAscending: Bool = false {
        didSet {
            syncIfPossible()
        }
    }

    let initialMarketFieldIndex: Int = 1

    init(marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit) {
        self.marketKit = marketKit
        self.currencyKit = currencyKit

        syncMarketInfos()
    }

    private func syncMarketInfos() {
        tasks = Set()

        if case .failed = state {
            state = .loading
        }

        Task { [weak self, marketKit, currency] in
            do {
                let marketInfos = try await marketKit.marketInfos(top: MarketModule.MarketTop.top100.rawValue, currencyCode: currency.code, defi: true)

                let rankedItems = marketInfos.enumerated().map { index, info in
                    Item(marketInfo: info, tvlRank: index + 1)
                }

                self?.sync(items: rankedItems)
            } catch {
                self?.state = .failed(error: error)
            }
        }.store(in: &tasks)
    }

    private func sync(items: [Item], reorder: Bool = false) {
        state = .loaded(items: sorted(items: items), softUpdate: false, reorder: reorder)
    }

    private func syncIfPossible() {
        guard case .loaded(let items, _, _) = state else {
            return
        }

        sync(items: items, reorder: true)
    }

    func sorted(items: [Item]) -> [Item] {
        items.sorted { lhsItem, rhsItem in
            if sortDirectionAscending {
                return lhsItem.tvlRank > rhsItem.tvlRank
            } else {
                return lhsItem.tvlRank < rhsItem.tvlRank
            }
        }
    }

}

extension MarketGlobalDefiMetricService: IMarketListService {

    var statePublisher: AnyPublisher<MarketListServiceState<Item>, Never> {
        $state
    }

    func refresh() {
        syncMarketInfos()
    }

}

extension MarketGlobalDefiMetricService: IMarketListCoinUidService {

    func coinUid(index: Int) -> String? {
        guard case .loaded(let items, _, _) = state, index < items.count else {
            return nil
        }

        return items[index].marketInfo.fullCoin.coin.uid
    }

}

extension MarketGlobalDefiMetricService: IMarketListDecoratorService {

    var currency: Currency {
        currencyKit.baseCurrency
    }

    var priceChangeType: MarketModule.PriceChangeType {
        .day
    }

    func onUpdate(marketFieldIndex: Int) {
        if case .loaded(let items, _, _) = state {
            state = .loaded(items: items, softUpdate: false, reorder: false)
        }
    }

}

extension MarketGlobalDefiMetricService {

    struct DefiItem {
        let marketInfo: MarketInfo
        let tvlRank: Int
    }

}

import RxSwift
import RxRelay
import MarketKit
import CurrencyKit

class MarketGlobalDefiMetricService: IMarketSingleSortHeaderService {
    typealias Item = DefiItem

    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let disposeBag = DisposeBag()
    private var syncDisposeBag = DisposeBag()

    private let stateRelay = PublishRelay<MarketListServiceState<DefiItem>>()
    private(set) var state: MarketListServiceState<DefiItem> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }
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
        syncDisposeBag = DisposeBag()

        if case .failed = state {
            state = .loading
        }

        marketKit.marketInfosSingle(top: MarketModule.MarketTop.top100.rawValue, currencyCode: currency.code, defi: true)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] marketInfos in
                    let rankedItems = marketInfos.enumerated().map { index, info in
                        Item(marketInfo: info, tvlRank: index + 1)
                    }
                    self?.sync(items: rankedItems)
                }, onError: { [weak self] error in
                    self?.state = .failed(error: error)
                })
                .disposed(by: syncDisposeBag)
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

    var stateObservable: Observable<MarketListServiceState<DefiItem>> {
        stateRelay.asObservable()
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
            stateRelay.accept(.loaded(items: items, softUpdate: false, reorder: false))
        }
    }

}

extension MarketGlobalDefiMetricService {

    struct DefiItem {
        let marketInfo: MarketInfo
        let tvlRank: Int
    }

}

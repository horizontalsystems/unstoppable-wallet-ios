import Combine
import RxSwift
import RxRelay
import MarketKit
import CurrencyKit
import HsExtensions

class MarketTopService: IMarketMultiSortHeaderService {
    typealias Item = MarketInfo

    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let disposeBag = DisposeBag()
    private var tasks = Set<AnyTask>()

    private var internalState: State = .loading {
        didSet {
            syncState()
        }
    }

    @PostPublished private(set) var state: MarketListServiceState<MarketInfo> = .loading

    var marketTop: MarketModule.MarketTop {
        didSet {
            syncIfPossible()
        }
    }

    var sortingField: MarketModule.SortingField {
        didSet {
            syncIfPossible()
        }
    }

    let initialMarketFieldIndex: Int

    init(marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, marketTop: MarketModule.MarketTop, sortingField: MarketModule.SortingField, marketField: MarketModule.MarketField) {
        self.marketKit = marketKit
        self.currencyKit = currencyKit
        self.marketTop = marketTop
        self.sortingField = sortingField
        initialMarketFieldIndex = marketField.rawValue

        syncMarketInfos()
    }

    private func syncMarketInfos() {
        tasks = Set()

        if case .failed = state {
            internalState = .loading
        }

        Task { [weak self, marketKit, currency] in
            do {
                let marketInfos = try await marketKit.marketInfos(top: 1000, currencyCode: currency.code)
                self?.internalState = .loaded(marketInfos: marketInfos)
            } catch {
                self?.internalState = .failed(error: error)
            }
        }.store(in: &tasks)
    }

    private func syncState(reorder: Bool = false) {
        switch internalState {
        case .loading:
            state = .loading
        case .loaded(let marketInfos):
            let marketInfos: [MarketInfo] = Array(marketInfos.prefix(marketTop.rawValue))
            state = .loaded(items: marketInfos.sorted(sortingField: sortingField, priceChangeType: priceChangeType), softUpdate: false, reorder: reorder)
        case .failed(let error):
            state = .failed(error: error)
        }
    }

    private func syncIfPossible() {
        guard case .loaded = internalState else {
            return
        }

        syncState(reorder: true)
    }

}

extension MarketTopService: IMarketListService {

    var statePublisher: AnyPublisher<MarketListServiceState<Item>, Never> {
        $state
    }

    func refresh() {
        syncMarketInfos()
    }

}

extension MarketTopService: IMarketListCoinUidService {

    func coinUid(index: Int) -> String? {
        guard case .loaded(let marketInfos, _, _) = state, index < marketInfos.count else {
            return nil
        }

        return marketInfos[index].fullCoin.coin.uid
    }

}

extension MarketTopService: IMarketListDecoratorService {

    var currency: Currency {
        currencyKit.baseCurrency
    }

    var priceChangeType: MarketModule.PriceChangeType {
        .day
    }

    func onUpdate(marketFieldIndex: Int) {
        if case .loaded(let marketInfos, _, _) = state {
            state = .loaded(items: marketInfos, softUpdate: false, reorder: false)
        }
    }

}

extension MarketTopService {

    private enum State {
        case loading
        case loaded(marketInfos: [MarketInfo])
        case failed(error: Error)
    }

}

import Combine
import Foundation
import HsExtensions
import MarketKit
import RxRelay
import RxSwift

class MarketOverviewService {
    private let marketKit: MarketKit.Kit
    private let currencyManager: CurrencyManager
    private let appManager: IAppManager
    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()
    private var tasks = Set<AnyTask>()

    @PostPublished private(set) var state: DataStatus<Item> = .loading

    init(marketKit: MarketKit.Kit, currencyManager: CurrencyManager, appManager: IAppManager) {
        self.marketKit = marketKit
        self.currencyManager = currencyManager
        self.appManager = appManager
    }

    private func syncState() {
        tasks = Set()

        if case .failed = state {
            state = .loading
        }

        Task { [weak self, marketKit, currency] in
            do {
                let currencyCode = currency.code

                async let marketOverview = try marketKit.marketOverview(currencyCode: currencyCode)
                async let topMovers = try marketKit.topMovers(currencyCode: currencyCode)

                let item = try await Item(marketOverview: marketOverview, topMovers: topMovers)
                self?.state = .completed(item)
            } catch {
                self?.state = .failed(error)
            }
        }.store(in: &tasks)
    }
}

extension MarketOverviewService {
    var currency: Currency {
        currencyManager.baseCurrency
    }

    func load() {
        currencyManager.$baseCurrency
            .sink { [weak self] _ in
                self?.syncState()
            }
            .store(in: &cancellables)

        subscribe(disposeBag, appManager.willEnterForegroundObservable) { [weak self] in self?.syncState() }

        syncState()
    }

    func refresh() {
        syncState()
    }
}

extension MarketOverviewService {
    struct Item {
        let marketOverview: MarketOverview
        let topMovers: TopMovers
    }
}

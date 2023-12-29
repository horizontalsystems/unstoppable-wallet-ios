import Combine
import HsExtensions
import MarketKit
import RxSwift

class MarketTopPairsViewModel {
    typealias Item = MarketPair

    private let marketKit: MarketKit.Kit
    private let currencyManager: CurrencyManager
    private var disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()
    private var tasks = Set<AnyTask>()

    @PostPublished private(set) var state: MarketListServiceState<MarketPair> = .loading

    init(marketKit: MarketKit.Kit, currencyManager: CurrencyManager, appManager: IAppManager) {
        self.marketKit = marketKit
        self.currencyManager = currencyManager

        currencyManager.$baseCurrency
            .sink { [weak self] _ in
                self?.sync()
            }
            .store(in: &cancellables)

        subscribe(disposeBag, appManager.willEnterForegroundObservable) { [weak self] in self?.sync() }

        sync()
    }

    private func sync() {
        tasks = Set()

        if case .failed = state {
            state = .loading
        }

        Task { [weak self, marketKit, currency] in
            do {
                let topPairs = try await marketKit.topPairs(currencyCode: currency.code)
                self?.state = .loaded(items: topPairs, softUpdate: false, reorder: false)
            } catch {
                self?.state = .failed(error: error)
            }
        }.store(in: &tasks)
    }

    func marketPair(uid: String) -> MarketPair? {
        guard case let .loaded(data, _, _) = state else {
            return nil
        }

        return data.first { $0.uid == uid }
    }
}

extension MarketTopPairsViewModel: IMarketListService {
    var statePublisher: AnyPublisher<MarketListServiceState<Item>, Never> {
        $state
    }

    func refresh() {
        sync()
    }
}

extension MarketTopPairsViewModel: IMarketListMarketPairDecoratorService {
    var currency: Currency {
        currencyManager.baseCurrency
    }
}

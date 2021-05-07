import CurrencyKit
import RxSwift
import RxRelay

protocol IMarketListFetcher {
    func fetchSingle(currencyCode: String) -> Single<[MarketModule.Item]>
    var refetchObservable: Observable<()> { get }
}

class MarketListService {
    private let currencyKit: CurrencyKit.Kit
    private let fetcher: IMarketListFetcher

    private var disposeBag = DisposeBag()
    private var fetchDisposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    private(set) var items = [MarketModule.Item]()

    init(currencyKit: CurrencyKit.Kit, fetcher: IMarketListFetcher) {
        self.currencyKit = currencyKit
        self.fetcher = fetcher

        subscribe(disposeBag, fetcher.refetchObservable) { [weak self] in
            self?.refetch()
        }

        subscribe(disposeBag, currencyKit.baseCurrencyUpdatedObservable) { [weak self] baseCurrency in self?.refetch() }
        fetch()
    }

    private func fetch() {
        fetchDisposeBag = DisposeBag()

        state = .loading

        fetcher.fetchSingle(currencyCode: currencyKit.baseCurrency.code)
                .subscribe(onSuccess: { [weak self] items in
                    self?.items = items
                    self?.state = .loaded
                }, onError: { [weak self] error in
                    self?.state = .failed(error: error)
                })
                .disposed(by: fetchDisposeBag)
    }

}

extension MarketListService {

    var allMarketFields: [MarketModule.MarketField] {
        [.marketCap, .volume, .price]
    }

    var currency: Currency {
        currencyKit.baseCurrency
    }

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    func refresh() {
        fetch()
    }

    func refetch() {
        items = []
        fetch()
    }

}

extension MarketListService {

    enum State {
        case loaded
        case loading
        case failed(error: Error)
    }

}

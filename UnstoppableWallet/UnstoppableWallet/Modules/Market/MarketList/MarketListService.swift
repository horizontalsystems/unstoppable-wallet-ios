import CurrencyKit
import XRatesKit
import Foundation
import RxSwift
import RxRelay

class MarketListService {
    private let disposeBag = DisposeBag()
    private var topItemsDisposable: Disposable?

    private let currencyKit: ICurrencyKit
    private let dataSource: IMarketListDataSource

    private let stateRelay = BehaviorRelay<State>(value: .loading)
    private(set) var items = [MarketListDataSource.Item]()

    public var period: MarketListDataSource.Period = .day {
        didSet {
            fetch()
        }
    }

    init(currencyKit: ICurrencyKit, dataSource: IMarketListDataSource) {
        self.currencyKit = currencyKit
        self.dataSource = dataSource

        fetch()
    }

    private func fetch() {
        topItemsDisposable?.dispose()
        topItemsDisposable = nil

        stateRelay.accept(.loading)

        topItemsDisposable = dataSource.itemsSingle(currencyCode: currency.code, period: period)
                .subscribe(onSuccess: { [weak self] in self?.sync(items: $0) })

        topItemsDisposable?.disposed(by: disposeBag)
    }

    private func sync(items: [MarketListDataSource.Item]) {
        self.items = items

        stateRelay.accept(.loaded)
    }

}

extension MarketListService {

    public var currency: Currency {
        currencyKit.baseCurrency
    }

    public var periods: [MarketListDataSource.Period] {
        MarketListDataSource.Period.allCases
    }

    public var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    public func refresh() {
        fetch()
    }

}

extension MarketListService {

    enum State {
        case loaded
        case loading
        case error(error: Error)
    }

}

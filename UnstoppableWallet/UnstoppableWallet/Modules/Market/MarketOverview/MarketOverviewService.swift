import Foundation
import RxSwift
import RxRelay
import CurrencyKit
import MarketKit

class MarketOverviewService {
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let appManager: IAppManager
    private let disposeBag = DisposeBag()
    private var syncDisposeBag = DisposeBag()

    private let stateRelay = PublishRelay<DataStatus<Item>>()
    private(set) var state: DataStatus<Item> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, appManager: IAppManager) {
        self.marketKit = marketKit
        self.currencyKit = currencyKit
        self.appManager = appManager
    }

    private func syncState() {
        syncDisposeBag = DisposeBag()

        if case .failed = state {
            state = .loading
        }

        let currencyCode = currency.code

        Single.zip(marketKit.marketOverviewSingle(currencyCode: currencyCode), marketKit.topMoversSingle(currencyCode: currencyCode))
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] marketOverview, topMovers in
                    let item = Item(marketOverview: marketOverview, topMovers: topMovers)
                    self?.state = .completed(item)
                }, onError: { [weak self] error in
                    self?.state = .failed(error)
                })
                .disposed(by: syncDisposeBag)
    }

}

extension MarketOverviewService {

    var stateObservable: Observable<DataStatus<Item>> {
        stateRelay.asObservable()
    }

    var currency: Currency {
        currencyKit.baseCurrency
    }

    func load() {
        subscribe(disposeBag, currencyKit.baseCurrencyUpdatedObservable) { [weak self] _ in self?.syncState() }
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

import RxSwift
import RxRelay
import MarketKit
import CurrencyKit

class CoinTreasuriesService {
    private let coin: Coin
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private var disposeBag = DisposeBag()

    private var internalState: DataStatus<[CoinTreasury]> = .loading {
        didSet {
            syncState()
        }
    }

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    private let sortDirectionAscendingRelay = PublishRelay<Bool>()
    var sortDirectionAscending: Bool = false {
        didSet {
            syncIfPossible(reorder: true)
            sortDirectionAscendingRelay.accept(sortDirectionAscending)
        }
    }

    private let typeFilterRelay = PublishRelay<TypeFilter>()
    var typeFilter: TypeFilter = .all {
        didSet {
            syncIfPossible()
            typeFilterRelay.accept(typeFilter)
        }
    }

    init(coin: Coin, marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit) {
        self.coin = coin
        self.marketKit = marketKit
        self.currencyKit = currencyKit

        syncTreasuries()
    }

    private func syncState(reorder: Bool = false) {
        switch internalState {
        case .loading:
            state = .loading
        case .completed(let treasuries):
            let treasuries = treasuries
                    .filter {
                        switch typeFilter {
                        case .all: return true
                        case .public: return $0.type == .public
                        case .private: return $0.type == .private
                        case .etf: return $0.type == .etf
                        }
                    }
                    .sorted { lhsTreasury, rhsTreasury in
                        sortDirectionAscending ? lhsTreasury.amount < rhsTreasury.amount : lhsTreasury.amount > rhsTreasury.amount
                    }

            state = .loaded(treasuries: treasuries, reorder: reorder)
        case .failed(let error):
            state = .failed(error: error)
        }
    }

    private func syncTreasuries() {
        disposeBag = DisposeBag()

        if case .failed = state {
            internalState = .loading
        }

        marketKit.treasuriesSingle(coinUid: coin.uid, currencyCode: currencyKit.baseCurrency.code)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] treasuries in
                    self?.internalState = .completed(treasuries)
                }, onError: { [weak self] error in
                    self?.internalState = .failed(error)
                })
                .disposed(by: disposeBag)
    }

    private func syncIfPossible(reorder: Bool = false) {
        guard case .completed = internalState else {
            return
        }

        syncState(reorder: reorder)
    }

}

extension CoinTreasuriesService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var sortDirectionAscendingObservable: Observable<Bool> {
        sortDirectionAscendingRelay.asObservable()
    }

    var typeFilterObservable: Observable<TypeFilter> {
        typeFilterRelay.asObservable()
    }

    var currency: Currency {
        currencyKit.baseCurrency
    }

    var coinCode: String {
        coin.code
    }

    func refresh() {
        syncTreasuries()
    }

}

extension CoinTreasuriesService {

    enum State {
        case loading
        case loaded(treasuries: [CoinTreasury], reorder: Bool)
        case failed(error: Error)
    }

    enum TypeFilter: CaseIterable {
        case all
        case `public`
        case `private`
        case etf
    }

}

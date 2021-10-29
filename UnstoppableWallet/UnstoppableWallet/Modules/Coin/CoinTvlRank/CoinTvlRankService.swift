//import RxSwift
//import RxRelay
//import CurrencyKit
//
//class CoinTvlRankService {
//    private let rateManager: IRateManager
//    let currency: Currency
//    private var disposeBag = DisposeBag()
//
//    private let chainRelay = PublishRelay<Chain>()
//    private(set) var chain: Chain = .all {
//        didSet {
//            chainRelay.accept(chain)
//        }
//    }
//
//    private let sortTypeRelay = PublishRelay<SortType>()
//    private(set) var sortType: SortType = .highestTvl {
//        didSet {
//            sortTypeRelay.accept(sortType)
//        }
//    }
//
//    private var internalState: State = .loading {
//        didSet {
//            syncState()
//        }
//    }
//
//    private let stateRelay = PublishRelay<State>()
//    private(set) var state: State = .loading {
//        didSet {
//            stateRelay.accept(state)
//        }
//    }
//
//    init(rateManager: IRateManager, currencyKit: CurrencyKit.Kit) {
//        self.rateManager = rateManager
//        currency = currencyKit.baseCurrency
//
//        sync()
//    }
//
//    private func sync() {
//        disposeBag = DisposeBag()
//
//        internalState = .loading
//
//        rateManager.topDefiTvlSingle(currencyCode: currency.code, fetchDiffPeriod: .hour24, itemsCount: 500, chain: nil)
//                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
//                .subscribe(onSuccess: { [weak self] defiTvls in
//                    self?.internalState = .loaded(defiTvls: defiTvls)
//                }, onError: { [weak self] _ in
//                    self?.internalState = .failed
//                })
//                .disposed(by: disposeBag)
//    }
//
//    private func sorted(defiTvls: [DefiTvl]) -> [DefiTvl] {
//        switch sortType {
//        case .highestTvl:
//            return defiTvls.sorted { $0.tvl > $1.tvl }
//        case .lowestTvl:
//            return defiTvls.sorted { $0.tvl < $1.tvl }
//        }
//    }
//
//    private func filtered(defiTvls: [DefiTvl]) -> [DefiTvl] {
//        switch chain {
//        case .all:
//            return defiTvls
//        default:
//            return defiTvls.filter { $0.chains.map { $0.lowercased() }.contains(chain.rawValue) }
//        }
//    }
//
//    private func syncState() {
//        switch internalState {
//        case .loaded(let defiTvls):
//            state = .loaded(defiTvls: sorted(defiTvls: filtered(defiTvls: defiTvls)))
//        default:
//            state = internalState
//        }
//    }
//
//}
//
//extension CoinTvlRankService {
//
//    var chainObservable: Observable<Chain> {
//        chainRelay.asObservable()
//    }
//
//    var sortTypeObservable: Observable<SortType> {
//        sortTypeRelay.asObservable()
//    }
//
//    var stateObservable: Observable<State> {
//        stateRelay.asObservable()
//    }
//
//    func set(chain: Chain) {
//        guard self.chain != chain else {
//            return
//        }
//
//        self.chain = chain
//
//        syncState()
//    }
//
//    func set(sortType: SortType) {
//        guard self.sortType != sortType else {
//            return
//        }
//
//        self.sortType = sortType
//
//        syncState()
//    }
//
//}
//
//extension CoinTvlRankService {
//
//    enum SortType: CaseIterable {
//        case highestTvl
//        case lowestTvl
//    }
//
//    enum Chain: String, CaseIterable {
//        case all
//        case ethereum
//        case binance
//        case solana
//        case avalanche
//        case polygon
//    }
//
//    enum State {
//        case loading
//        case failed
//        case loaded(defiTvls: [DefiTvl])
//    }
//
//}

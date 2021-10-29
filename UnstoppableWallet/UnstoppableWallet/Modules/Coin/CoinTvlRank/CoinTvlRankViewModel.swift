//import Foundation
//import RxSwift
//import RxRelay
//import RxCocoa
//import MarketKit
//
//class CoinTvlRankViewModel {
//    private let service: CoinTvlRankService
//    private let disposeBag = DisposeBag()
//
//    private let filterRelay = BehaviorRelay<String>(value: "")
//    private let sortDescendingRelay = BehaviorRelay<Bool>(value: true)
//    private let stateRelay = BehaviorRelay<State>(value: .loading)
//
//    init(service: CoinTvlRankService) {
//        self.service = service
//
//        subscribe(disposeBag, service.chainObservable) { [weak self] in self?.sync(chain: $0) }
//        subscribe(disposeBag, service.sortTypeObservable) { [weak self] in self?.sync(sortType: $0) }
//        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
//
//        sync(chain: service.chain)
//        sync(sortType: service.sortType)
//        sync(state: service.state)
//    }
//
//    private func title(chain: CoinTvlRankService.Chain) -> String {
//        switch chain {
//        case .all: return "coin_page.tvl_rank.filters.all".localized
//        default: return chain.rawValue.capitalized
//        }
//    }
//
////    private func title(sortType: CoinTvlRankService.SortType) -> String {
////        switch sortType {
////        case .highestTvl: return "coin_page.tvl_rank.sort_by.highest_tvl".localized
////        case .lowestTvl: return "coin_page.tvl_rank.sort_by.lowest_tvl".localized
////        }
////    }
//
//    private func sync(chain: CoinTvlRankService.Chain) {
//        filterRelay.accept(title(chain: chain))
//    }
//
//    private func sync(sortType: CoinTvlRankService.SortType) {
//        sortDescendingRelay.accept(sortType == .highestTvl)
//    }
//
//    private func chainDescription(chains: [String]) -> String {
//        if chains.isEmpty {
//            return ""
//        } else if chains.count == 1 {
//            return chains[0].lowercased().capitalized
//        } else {
//            return "coin_page.tvl_rank.multi_chain".localized
//        }
//    }
//
//    private func viewItem(defiTvl: DefiTvl) -> ViewItem {
//        ViewItem(
//                coinType: defiTvl.data.coinType.coinType,
//                coinTitle: defiTvl.data.name,
//                rank: "\(defiTvl.tvlRank)",
//                chain: chainDescription(chains: defiTvl.chains),
//                volume: CurrencyCompactFormatter.instance.format(currency: service.currency, value: defiTvl.tvl),
//                diff: defiTvl.tvlDiff
//        )
//    }
//
//    private func sync(state: CoinTvlRankService.State) {
//        switch state {
//        case .loading:
//            stateRelay.accept(.loading)
//        case .failed:
//            stateRelay.accept(.failed)
//        case .loaded(let defiTvls):
//            let viewItems = defiTvls.map { viewItem(defiTvl: $0) }
//            stateRelay.accept(.loaded(viewItems: viewItems))
//        }
//    }
//
//}
//
//extension CoinTvlRankViewModel {
//
//    var filterDriver: Driver<String> {
//        filterRelay.asDriver()
//    }
//
//    var sortDescendingDriver: Driver<Bool> {
//        sortDescendingRelay.asDriver()
//    }
//
//    var stateDriver: Driver<State> {
//        stateRelay.asDriver()
//    }
//
//    var filterViewItems: [AlertViewItem] {
//        CoinTvlRankService.Chain.allCases.map { chain in
//            AlertViewItem(text: title(chain: chain), selected: service.chain == chain)
//        }
//    }
//
//    func onSelectFilter(index: Int) {
//        service.set(chain: CoinTvlRankService.Chain.allCases[index])
//    }
//
//    func onSwitchSortType() {
//        service.set(sortType: service.sortType == .highestTvl ? .lowestTvl : .highestTvl)
//    }
//
//}
//
//extension CoinTvlRankViewModel {
//
//    enum State {
//        case loading
//        case failed
//        case loaded(viewItems: [ViewItem])
//    }
//
//    struct ViewItem {
//        let coinType: CoinType
//        let coinTitle: String
//        let rank: String?
//        let chain: String?
//        let volume: String?
//        let diff: Decimal
//    }
//
//}

import Combine
import Foundation
import MarketKit
import RxCocoa
import RxRelay
import RxSwift

class MarketOverviewTopPairsViewModel {
    private let service: MarketOverviewTopPairsService
    private let decorator: MarketListMarketPairDecorator
    private var cancellables = Set<AnyCancellable>()

    private let listViewItemsRelay = BehaviorRelay<[MarketModule.ListViewItem]?>(value: nil)

    init(service: MarketOverviewTopPairsService, decorator: MarketListMarketPairDecorator) {
        self.service = service
        self.decorator = decorator

        service.$marketPairs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.sync(marketPairs: $0) }
            .store(in: &cancellables)

        sync(marketPairs: service.marketPairs)
    }

    private func sync(marketPairs: [MarketPair]?) {
        listViewItemsRelay.accept(marketPairs.map { $0.map { decorator.listViewItem(item: $0) } })
    }
}

extension MarketOverviewTopPairsViewModel {
    func marketPair(uid: String) -> MarketPair? {
        service.marketPairs?.first { $0.uid == uid }
    }
}

extension MarketOverviewTopPairsViewModel: IBaseMarketOverviewTopListViewModel {
    var listViewItemsDriver: Driver<[MarketModule.ListViewItem]?> {
        listViewItemsRelay.asDriver()
    }

    var selectorTitles: [String] {
        []
    }

    var selectorIndex: Int {
        0
    }

    func onSelect(selectorIndex _: Int) {}
}

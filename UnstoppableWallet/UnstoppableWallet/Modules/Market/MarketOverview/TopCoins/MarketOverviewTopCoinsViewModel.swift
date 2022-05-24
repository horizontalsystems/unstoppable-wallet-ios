import RxSwift
import RxRelay
import RxCocoa
import CurrencyKit
import MarketKit

class MarketOverviewTopCoinsViewModel {
    private let service: MarketOverviewTopCoinsService
    private let decorator: MarketListMarketFieldDecorator
    private let disposeBag = DisposeBag()

    private let listViewItemsRelay = BehaviorRelay<[MarketModule.ListViewItem]?>(value: nil)

    init(service: MarketOverviewTopCoinsService, decorator: MarketListMarketFieldDecorator) {
        self.service = service
        self.decorator = decorator

        subscribe(disposeBag, service.marketInfosObservable) { [weak self] in self?.sync(marketInfos: $0) }

        sync(marketInfos: service.marketInfos)
    }

    private func sync(marketInfos: [MarketInfo]?) {
        listViewItemsRelay.accept(marketInfos.map { $0.map { decorator.listViewItem(item: $0) } })
    }

}

extension MarketOverviewTopCoinsViewModel {

    var marketTop: MarketModule.MarketTop {
        service.marketTop
    }

    var listType: MarketOverviewTopCoinsService.ListType {
        service.listType
    }

}

extension MarketOverviewTopCoinsViewModel: IBaseMarketOverviewTopListViewModel {

    var listViewItemsDriver: Driver<[MarketModule.ListViewItem]?> {
        listViewItemsRelay.asDriver()
    }

    var selectorTitles: [String] {
        MarketModule.MarketTop.allCases.map { $0.title }
    }

    var selectorIndex: Int {
        MarketModule.MarketTop.allCases.firstIndex(of: service.marketTop) ?? 0
    }

    func onSelect(selectorIndex: Int) {
        let marketTop = MarketModule.MarketTop.allCases[selectorIndex]
        service.set(marketTop: marketTop)
    }

}

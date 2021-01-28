import Foundation
import RxSwift
import RxRelay
import RxCocoa

class MarketTabsViewModel {
    private let disposeBag = DisposeBag()
    private let service: MarketTabsService

    private var updateIndexRelay = PublishRelay<()>()

    init(service: MarketTabsService) {
        self.service = service

        subscribe(disposeBag, service.currentTabChangedObservable) { [weak self] in self?.syncCurrentTab() }
    }

    private func syncCurrentTab() {
        updateIndexRelay.accept(())
    }

}

extension MarketTabsViewModel {
    public var currentIndex: Int { service.currentTab.rawValue }
    public var tabs: [FilterHeaderView.ViewItem] { service.tabs.map { FilterHeaderView.ViewItem.item(title: $0.title) } }

    public func didSelect(index: Int) {
        guard index < tabs.count else {
            return
        }

        service.currentTab = service.tabs[index]
    }

    public var updateIndexSignal: Signal<()> {
        updateIndexRelay.asSignal()
    }

}

extension MarketModule.Tab {

    var title: String {
        switch self {
        case .overview: return "market.category.overview".localized
        case .discovery: return "market.category.discovery".localized
        case .watchlist: return "market.category.watchlist".localized
        }
    }

}

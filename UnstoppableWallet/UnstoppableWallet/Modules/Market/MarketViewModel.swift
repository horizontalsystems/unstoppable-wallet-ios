import Foundation
import RxSwift
import RxRelay
import RxCocoa

class MarketViewModel {
    private let disposeBag = DisposeBag()

    public let tabsService: MarketTabsService

    private let updateTabRelay = PublishRelay<()>()

    init(tabsService: MarketTabsService) {
        self.tabsService = tabsService

        subscribe(disposeBag, tabsService.currentTabChangedObservable) { [weak self] in self?.updateTab() }
    }

    private func updateTab() {
        updateTabRelay.accept(())
    }

}

extension MarketViewModel {

    var updateTabSignal: Signal<()> {
        updateTabRelay.asSignal()
    }

    var currentTabIndex: Int {
        get {
            tabsService.currentTab.rawValue
        }
        set {
            guard let category = MarketModule.Tab(rawValue: newValue) else {
                return
            }
            tabsService.currentTab = category
        }
    }

}

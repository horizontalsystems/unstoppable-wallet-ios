import Foundation
import RxSwift
import RxRelay

class MarketTabsService {
    private let disposeBag = DisposeBag()
    private let localStorage: ILocalStorage

    private var currentTabChangedRelay = PublishRelay<()>()

    public var currentTab: MarketModule.Tab {
        get {
            localStorage.marketCategory.flatMap { MarketModule.Tab(rawValue: $0) } ?? tabs[0]
        }
        set {
            localStorage.marketCategory = newValue.rawValue
            currentTabChangedRelay.accept(())
        }
    }

    init(localStorage: ILocalStorage) {
        self.localStorage = localStorage
    }

}

extension MarketTabsService {

    public var tabs: [MarketModule.Tab] {
        MarketModule.Tab.allCases
    }

    public var currentTabChangedObservable: Observable<()> {
        currentTabChangedRelay.asObservable()
    }

}

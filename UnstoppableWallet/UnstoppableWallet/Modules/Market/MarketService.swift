class MarketService {
    private let localStorage: ILocalStorage

    init(localStorage: ILocalStorage) {
        self.localStorage = localStorage
    }

}

extension MarketService {

    var currentTab: MarketModule.Tab? {
        get {
            localStorage.marketCategory.flatMap { MarketModule.Tab(rawValue: $0) }
        }
        set {
            localStorage.marketCategory = newValue?.rawValue
        }
    }

}

import RxSwift
import RxRelay
import RxCocoa

class MarketTvlSortHeaderViewModel {
    private let service: MarketGlobalTvlMetricService
    private let decorator: MarketListTvlDecorator

    private let sortDirectionRelay: BehaviorRelay<Bool>

    init(service: MarketGlobalTvlMetricService, decorator: MarketListTvlDecorator) {
        self.service = service
        self.decorator = decorator

        sortDirectionRelay = BehaviorRelay(value: service.sortDirectionAscending)
    }

}

extension MarketTvlSortHeaderViewModel {

    var platformFields: [String] {
        MarketModule.MarketPlatformField.allCases.map { $0.title }
    }

    var marketTvlFields: [String] {
        MarketModule.MarketTvlField.allCases.map { $0.title }
    }

    var sortDirectionAscending: Bool {
        service.sortDirectionAscending
    }

    var platformFieldIndex: Int {
        MarketModule.MarketPlatformField.allCases.firstIndex(of: service.marketPlatformField) ?? 0
    }

    var marketTvlFieldIndex: Int {
        MarketModule.MarketTvlField.allCases.firstIndex(of: service.marketTvlField) ?? 0
    }

    var sortDirectionDriver: Driver<Bool> {
        sortDirectionRelay.asDriver()
    }

    func onToggleSortDirection() {
        service.sortDirectionAscending = !service.sortDirectionAscending
        sortDirectionRelay.accept(service.sortDirectionAscending)
    }

    func onSelectMarketPlatformField(index: Int) {
        service.marketPlatformField = MarketModule.MarketPlatformField.allCases[index]
    }

    func onSelectMarketTvlField(index: Int) {
        service.marketTvlField = MarketModule.MarketTvlField.allCases[index]
    }

}

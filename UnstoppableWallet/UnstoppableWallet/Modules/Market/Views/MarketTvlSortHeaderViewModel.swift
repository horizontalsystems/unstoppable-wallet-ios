import RxSwift
import RxRelay
import RxCocoa

class MarketTvlSortHeaderViewModel {
    private let service: MarketGlobalTvlMetricService
    private let decorator: MarketListTvlDecorator

    private let platformFieldRelay: BehaviorRelay<String>
    private let sortDirectionAscendingRelay: BehaviorRelay<Bool>
    private let marketTvlFieldRelay: BehaviorRelay<MarketModule.MarketTvlField>

    init(service: MarketGlobalTvlMetricService, decorator: MarketListTvlDecorator) {
        self.service = service
        self.decorator = decorator

        platformFieldRelay = BehaviorRelay(value: service.marketPlatformField.title)
        sortDirectionAscendingRelay = BehaviorRelay(value: service.sortDirectionAscending)
        marketTvlFieldRelay = BehaviorRelay(value: service.marketTvlField)
    }

}

extension MarketTvlSortHeaderViewModel {

    var platformFieldViewItems: [AlertViewItem] {
        MarketModule.MarketPlatformField.allCases.map { platformField in
            AlertViewItem(text: platformField.title, selected: service.marketPlatformField == platformField)
        }
    }

    var marketTvlFields: [MarketModule.MarketTvlField] {
        MarketModule.MarketTvlField.allCases
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

    var platformFieldDriver: Driver<String> {
        platformFieldRelay.asDriver()
    }

    var sortDirectionDriver: Driver<Bool> {
        sortDirectionAscendingRelay.asDriver()
    }

    var marketTvlFieldDriver: Driver<MarketModule.MarketTvlField> {
        marketTvlFieldRelay.asDriver()
    }

    func onToggleSortDirection() {
        service.sortDirectionAscending = !service.sortDirectionAscending
        sortDirectionAscendingRelay.accept(service.sortDirectionAscending)
    }

    func onToggleMarketTvlField() {
        switch service.marketTvlField {
        case .value: service.marketTvlField = .diff
        case .diff: service.marketTvlField = .value
        }
        marketTvlFieldRelay.accept(service.marketTvlField)
    }

    func onSelectMarketPlatformField(index: Int) {
        service.marketPlatformField = MarketModule.MarketPlatformField.allCases[index]
        platformFieldRelay.accept(service.marketPlatformField.title)
    }

}

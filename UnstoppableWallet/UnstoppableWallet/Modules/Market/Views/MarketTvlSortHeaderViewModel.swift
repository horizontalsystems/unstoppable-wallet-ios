import RxSwift
import RxRelay
import RxCocoa

class MarketTvlSortHeaderViewModel {
    private let service: MarketGlobalTvlMetricService
    private let decorator: MarketListTvlDecorator

    private let platformFieldRelay: BehaviorRelay<String>
    private let sortDirectionAscendingRelay: BehaviorRelay<Bool>

    init(service: MarketGlobalTvlMetricService, decorator: MarketListTvlDecorator) {
        self.service = service
        self.decorator = decorator

        platformFieldRelay = BehaviorRelay(value: service.marketPlatformField.title)
        sortDirectionAscendingRelay = BehaviorRelay(value: service.sortDirectionAscending)
    }

}

extension MarketTvlSortHeaderViewModel {

    var platformFieldViewItems: [AlertViewItem] {
        MarketModule.MarketPlatformField.allCases.map { platformField in
            AlertViewItem(text: platformField.title, selected: service.marketPlatformField == platformField)
        }
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

    var platformFieldDriver: Driver<String> {
        platformFieldRelay.asDriver()
    }

    var sortDirectionDriver: Driver<Bool> {
        sortDirectionAscendingRelay.asDriver()
    }

    func onToggleSortDirection() {
        service.sortDirectionAscending = !service.sortDirectionAscending
        sortDirectionAscendingRelay.accept(service.sortDirectionAscending)
    }

    func onSelectMarketPlatformField(index: Int) {
        service.marketPlatformField = MarketModule.MarketPlatformField.allCases[index]
        platformFieldRelay.accept(service.marketPlatformField.title)
    }

    func onSelectMarketTvlField(index: Int) {
        service.marketTvlField = MarketModule.MarketTvlField.allCases[index]
    }

    func onSelectPriceChangeField(index: Int) {
        service.setPriceChange(index: index)
    }

}

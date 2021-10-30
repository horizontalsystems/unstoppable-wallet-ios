import RxSwift
import RxRelay
import RxCocoa

protocol IMarketSingleSortHeaderService: AnyObject {
    var sortDirectionAscending: Bool { get set }
}

protocol IMarketSingleSortHeaderDecorator: AnyObject {
    var allFields: [String] { get }
    var currentFieldIndex: Int { get }
    func setCurrentField(index: Int)
}

class MarketSingleSortHeaderViewModel {
    private let service: IMarketSingleSortHeaderService
    private let decorator: IMarketSingleSortHeaderDecorator

    private let sortDirectionRelay: BehaviorRelay<Bool>

    init(service: IMarketSingleSortHeaderService, decorator: IMarketSingleSortHeaderDecorator) {
        self.service = service
        self.decorator = decorator

        sortDirectionRelay = BehaviorRelay(value: service.sortDirectionAscending)
    }

}

extension MarketSingleSortHeaderViewModel {

    var allFields: [String] {
        decorator.allFields
    }

    var sortDirectionAscending: Bool {
        service.sortDirectionAscending
    }

    var currentFieldIndex: Int {
        decorator.currentFieldIndex
    }

    var sortDirectionDriver: Driver<Bool> {
        sortDirectionRelay.asDriver()
    }

    func onToggleSortDirection() {
        service.sortDirectionAscending = !service.sortDirectionAscending
        sortDirectionRelay.accept(service.sortDirectionAscending)
    }

    func onSelectField(index: Int) {
        decorator.setCurrentField(index: index)
    }

}

import RxSwift
import RxRelay
import RxCocoa

protocol IMarketSingleSortHeaderService: AnyObject {
    var sortDirectionAscending: Bool { get set }
}

class MarketSingleSortHeaderViewModel {
    private let service: IMarketSingleSortHeaderService
    private let listViewModel: MarketListViewModel

    private let sortDirectionRelay: BehaviorRelay<Bool>

    init(service: IMarketSingleSortHeaderService, listViewModel: MarketListViewModel) {
        self.service = service
        self.listViewModel = listViewModel

        sortDirectionRelay = BehaviorRelay(value: service.sortDirectionAscending)
    }

}

extension MarketSingleSortHeaderViewModel {

    var marketFields: [String] {
        MarketModule.MarketField.allCases.map { $0.title }
    }

    var sortDirectionAscending: Bool {
        service.sortDirectionAscending
    }

    var marketFieldIndex: Int {
        MarketModule.MarketField.allCases.firstIndex(of: listViewModel.marketField) ?? 0
    }

    var sortDirectionDriver: Driver<Bool> {
        sortDirectionRelay.asDriver()
    }

    func onToggleSortDirection() {
        service.sortDirectionAscending = !service.sortDirectionAscending
        sortDirectionRelay.accept(service.sortDirectionAscending)
    }

    func onSelectMarketField(index: Int) {
        listViewModel.marketField = MarketModule.MarketField.allCases[index]
    }

}

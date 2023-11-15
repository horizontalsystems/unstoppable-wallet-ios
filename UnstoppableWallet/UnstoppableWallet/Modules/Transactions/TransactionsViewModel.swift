import Combine
import RxCocoa
import RxRelay
import RxSwift

class TransactionsViewModel: BaseTransactionsViewModel {
    private let service: TransactionsService
    private var cancellables = Set<AnyCancellable>()

    private let filterBadgeVisibleRelay = BehaviorRelay<Bool>(value: false)

    init(service: TransactionsService, contactLabelService: TransactionsContactLabelService, factory: TransactionsViewItemFactory) {
        self.service = service

        super.init(service: service, contactLabelService: contactLabelService, factory: factory)

        service.filterService.$transactionFilter
            .sink { [weak self] in self?.sync(transactionFilter: $0) }
            .store(in: &cancellables)

        sync(transactionFilter: service.filterService.transactionFilter)
    }

    private func sync(transactionFilter: TransactionFilter) {
        filterBadgeVisibleRelay.accept(transactionFilter.hasChanges)
    }

    var filterBadgeVisibleDriver: Driver<Bool> {
        filterBadgeVisibleRelay.asDriver()
    }
}

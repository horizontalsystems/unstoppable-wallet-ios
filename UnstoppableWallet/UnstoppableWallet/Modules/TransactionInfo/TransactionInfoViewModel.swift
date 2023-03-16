import RxSwift
import RxCocoa
import MarketKit
import CurrencyKit

class TransactionInfoViewModel {
    private let disposeBag = DisposeBag()

    private let service: TransactionInfoService
    private let factory: TransactionInfoViewItemFactory
    private let contactLabelService: ContactLabelService

    private var viewItemsRelay = PublishRelay<[[TransactionInfoModule.ViewItem]]>()

    init(service: TransactionInfoService, factory: TransactionInfoViewItemFactory, contactLabelService: ContactLabelService) {
        self.service = service
        self.factory = factory
        self.contactLabelService = contactLabelService

        subscribe(disposeBag, service.transactionItemUpdatedObserver) { [weak self] in self?.updateTransactionItem(item: $0) }
        subscribe(disposeBag, contactLabelService.stateObservable) { [weak self] _ in
            self?.reSyncServiceItem()
        }
    }

    private func reSyncServiceItem() {
        updateTransactionItem(item: service.item)
    }

    private func updateTransactionItem(item: TransactionInfoService.Item) {
        viewItemsRelay.accept(factory.items(item: item))
    }

}

extension TransactionInfoViewModel {

    var viewItems: [[TransactionInfoModule.ViewItem]] {
        factory.items(item: service.item)
    }

    var viewItemsDriver: Signal<[[TransactionInfoModule.ViewItem]]> {
        viewItemsRelay.asSignal()
    }

    var rawTransaction: String? {
        service.rawTransaction()
    }

    var transactionHash: String {
        service.item.record.transactionHash
    }

}

import Combine
import MarketKit
import RxCocoa
import RxSwift

class TransactionInfoViewModel {
    private let disposeBag = DisposeBag()

    private let service: TransactionInfoService
    private let factory: TransactionInfoViewItemFactory
    private let contactLabelService: ContactLabelService

    private var viewItemsRelay = PublishRelay<[TransactionInfoModule.SectionViewItem]>()

    init(service: TransactionInfoService, factory: TransactionInfoViewItemFactory, contactLabelService: ContactLabelService) {
        self.service = service
        self.factory = factory
        self.contactLabelService = contactLabelService

        subscribe(disposeBag, service.transactionItemUpdatedObserver) { [weak self] in self?.updateTransactionItem(item: $0) }
        subscribe(disposeBag, contactLabelService.stateObservable) { [weak self] _ in self?.reSyncServiceItem() }
        subscribe(disposeBag, service.balanceHiddenObservable) { [weak self] _ in self?.reSyncServiceItem() }
    }

    private func reSyncServiceItem() {
        updateTransactionItem(item: service.item)
    }

    private func updateTransactionItem(item: TransactionInfoService.Item) {
        viewItemsRelay.accept(factory.items(item: item, balanceHidden: service.balanceHidden))
    }
}

extension TransactionInfoViewModel {
    var viewItems: [TransactionInfoModule.SectionViewItem] {
        factory.items(item: service.item, balanceHidden: service.balanceHidden)
    }

    var viewItemsDriver: Signal<[TransactionInfoModule.SectionViewItem]> {
        viewItemsRelay.asSignal()
    }

    var rawTransaction: String? {
        service.rawTransaction()
    }

    var transactionHash: String {
        service.item.record.transactionHash
    }

    var transactionRecord: TransactionRecord {
        service.item.record
    }

    func togglePrice() {
        factory.priceReversed.toggle()
        reSyncServiceItem()

        stat(page: .transactionInfo, event: .togglePrice)
    }
}

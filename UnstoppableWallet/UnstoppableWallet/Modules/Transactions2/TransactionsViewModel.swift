import RxSwift
import RxCocoa
import CoinKit

class TransactionsViewModel {
    let disposeBag = DisposeBag()

    let service: TransactionsService
    let factory: TransactionsViewItemFactory

    private var viewItems = [TransactionsModule2.ViewItem]()

    private var coinFiltersRelay = BehaviorRelay<[String]>(value: [])
    private var viewItemsRelay = BehaviorRelay<[TransactionsModule2.ViewItem]>(value: [])
    private var updatedViewItemRelay = PublishRelay<TransactionsModule2.ViewItem>()
    private var viewStatusRelay = BehaviorRelay<TransactionViewStatus>(value: TransactionViewStatus(showProgress: false, showMessage: false))

    init(service: TransactionsService, factory: TransactionsViewItemFactory) {
        self.service = service
        self.factory = factory

        subscribe(disposeBag, service.walletsDriver) { [weak self] wallets in self?.handle(wallets: wallets) }
        subscribe(disposeBag, service.itemsDriverSignal) { [weak self] items in self?.handle(items: items) }
        subscribe(disposeBag, service.updatedItemSignal) { [weak self] item in self?.handle(updatedItem: item) }
        subscribe(disposeBag, service.syncingSignal) { [weak self] syncing in self?.handle(syncing: syncing) }
    }

    private func handle(wallets: [TransactionWallet]) {
        let coinFilters = wallets.map { factory.coinFilterName(wallet: $0) }
        coinFiltersRelay.accept(coinFilters)
    }

    private func handle(items: [TransactionsModule2.Item]) {
        print("viewModel received \(items.count) transactions: \(items.map { $0.record.transactionHash })")
        let viewItems = items.map { factory.viewItem(item: $0) }

        self.viewItems = viewItems
        viewItemsRelay.accept(viewItems)
    }

    private func handle(updatedItem: TransactionsModule2.Item) {
        print("viewModel received updatedItem \(updatedItem.record.transactionHash); currencyValue: \(updatedItem.currencyValue)")
        if let index = viewItems.firstIndex { item in item.uid == updatedItem.record.uid } {
            let viewItem = factory.viewItem(item: updatedItem)
            print("viewModel found updated view item \(viewItem.uid)")

            viewItems[index] = viewItem
            updatedViewItemRelay.accept(viewItem)
        }
    }

    private func handle(syncing: Bool) {
        if syncing {
            viewStatusRelay.accept(TransactionViewStatus(showProgress: true, showMessage: false))
        } else if viewItems.isEmpty {
            viewStatusRelay.accept(TransactionViewStatus(showProgress: false, showMessage: true))
        } else {
            viewStatusRelay.accept(TransactionViewStatus(showProgress: false, showMessage: false))
        }
    }

}

extension TransactionsViewModel {

    var coinFiltersDriver: Driver<[String]> {
        coinFiltersRelay.asDriver()
    }

    var viewItemsDriver: Driver<[TransactionsModule2.ViewItem]> {
        viewItemsRelay.asDriver()
    }

    var updatedViewItemSignal: Signal<TransactionsModule2.ViewItem> {
        updatedViewItemRelay.asSignal()
    }

    var viewStatusDriver: Driver<TransactionViewStatus> {
        viewStatusRelay.asDriver()
    }

    func willShow(uid: String) {
        service.fetchRate(for: uid)
    }

    func coinFilterSelected(index: Int?) {
        print("coinFilterSelected index \(index)")
        service.set(selectedCoinFilterIndex: index)
    }

    func bottomReached() {
        print("onBottomReached; loading \(viewItems.count + 10) transactions")
        service.load(count: viewItems.count + TransactionsModule2.pageLimit)
    }

}

import Foundation
import RxSwift
import RxRelay
import RxCocoa
import MarketKit

protocol IWalletService: AnyObject {
    var totalItem: WalletModule.TotalItem? { get }
    var balanceItems: [IBalanceItem] { get }
    var totalItemObservable: Observable<WalletModule.TotalItem?> { get }
    var balanceItemUpdatedObservable: Observable<IBalanceItem> { get }
    var balanceItemsObservable: Observable<[IBalanceItem]> { get }
    func balanceItem(item: WalletModule.Item) -> IBalanceItem?
    func disable(item: WalletModule.Item)
    func toggleConversionCoin()
    func refresh()
}

class WalletViewModel {
    private let commonService: WalletCommonService
    private let service: IWalletService
    private let factory: WalletViewItemFactory
    private let accountRestoreWarningFactory: AccountRestoreWarningFactory
    private let disposeBag = DisposeBag()

    private let titleRelay = BehaviorRelay<String?>(value: nil)
    private let displayModeRelay = BehaviorRelay<DisplayMode>(value: .list)
    private let headerViewItemRelay = BehaviorRelay<HeaderViewItem?>(value: nil)
    private let showWarningRelay = BehaviorRelay<CancellableTitledCaution?>(value: nil)
    private let sortByRelay = BehaviorRelay<String?>(value: nil)
    private let viewItemsRelay = BehaviorRelay<[BalanceViewItem]>(value: [])
    private let openReceiveRelay = PublishRelay<Wallet>()
    private let openBackupRequiredRelay = PublishRelay<Wallet>()
    private let openCoinPageRelay = PublishRelay<Coin>()
    private let noConnectionErrorRelay = PublishRelay<()>()
    private let openSyncErrorRelay = PublishRelay<(Wallet, Error)>()
    private let playHapticRelay = PublishRelay<()>()
    private let scrollToTopRelay = PublishRelay<()>()

    private var viewItems = [BalanceViewItem]()
    private var expandedItem: WalletModule.Item?

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.wallet-view-model", qos: .userInitiated)

    init(commonService: WalletCommonService, service: IWalletService, factory: WalletViewItemFactory, accountRestoreWarningFactory: AccountRestoreWarningFactory) {
        self.commonService = commonService
        self.service = service
        self.factory = factory
        self.accountRestoreWarningFactory = accountRestoreWarningFactory

        subscribe(disposeBag, commonService.activeAccountObservable) { [weak self] in self?.sync(activeAccount: $0) }
        subscribe(disposeBag, commonService.balanceHiddenObservable) { [weak self] _ in self?.onUpdateBalanceHidden() }
        subscribe(disposeBag, service.totalItemObservable) { [weak self] in self?.sync(totalItem: $0) }
        subscribe(disposeBag, service.balanceItemUpdatedObservable) { [weak self] in self?.syncUpdated(balanceItem: $0) }
        subscribe(disposeBag, service.balanceItemsObservable) { [weak self] in self?.sync(balanceItems: $0) }
        subscribe(disposeBag, commonService.sortTypeObservable) { [weak self] in self?.sync(sortType: $0, scrollToTop: true) }
        subscribe(disposeBag, commonService.balancePrimaryValueObservable) { [weak self] _ in self?.onUpdateBalancePrimaryValue() }

        sync(activeAccount: commonService.activeAccount)
        sync(totalItem: service.totalItem)
        sync(balanceItems: service.balanceItems)
        sync(sortType: commonService.sortType, scrollToTop: false)
    }

    private func sync(activeAccount: Account?) {
        titleRelay.accept(activeAccount?.name)

        if let account = activeAccount {
            showWarningRelay.accept(accountRestoreWarningFactory.caution(account: account, canIgnoreActiveAccountWarning: true))
        }
    }

    private func onUpdateBalanceHidden() {
        sync(balanceItems: service.balanceItems)
        sync(totalItem: service.totalItem)
    }

    private func onUpdateBalancePrimaryValue() {
        sync(balanceItems: service.balanceItems)
    }

    private func sync(totalItem: WalletModule.TotalItem?) {
        let headerViewItem = totalItem.map { factory.headerViewItem(totalItem: $0, balanceHidden: commonService.balanceHidden, watchAccount: commonService.watchAccount) }
        headerViewItemRelay.accept(headerViewItem)
    }

    private func sync(sortType: WalletModule.SortType, scrollToTop: Bool) {
        sortByRelay.accept(sortType.title)

        if scrollToTop {
            scrollToTopRelay.accept(())
        }
    }

    private func syncUpdated(balanceItem: IBalanceItem) {
        queue.async {
            guard let index = self.viewItems.firstIndex(where: { $0.item == balanceItem.item }) else {
                return
            }

            self.viewItems[index] = self.viewItem(balanceItem: balanceItem)
            self.viewItemsRelay.accept(self.viewItems)
        }
    }

    private func sync(balanceItems: [IBalanceItem]) {
        queue.async {
            self.viewItems = balanceItems.map {
                self.viewItem(balanceItem: $0)
            }
            self.viewItemsRelay.accept(self.viewItems)
        }

        displayModeRelay.accept(balanceItems.isEmpty ? (commonService.watchAccount ? .watchEmpty : .empty) : .list)
    }

    private func viewItem(balanceItem: IBalanceItem) -> BalanceViewItem {
        factory.viewItem(
                balanceItem: balanceItem,
                balancePrimaryValue: commonService.balancePrimaryValue,
                balanceHidden: commonService.balanceHidden,
                expanded: balanceItem.item == expandedItem
        )
    }

    private func syncViewItem(item: WalletModule.Item) {
        guard let balanceItem = service.balanceItem(item: item), let index = viewItems.firstIndex(where: { $0.item == item }) else {
            return
        }

        viewItems[index] = viewItem(balanceItem: balanceItem)
    }

}

extension WalletViewModel {

    var titleDriver: Driver<String?> {
        titleRelay.asDriver()
    }

    var displayModeDriver: Driver<DisplayMode> {
        displayModeRelay.asDriver()
    }

    var headerViewItemDriver: Driver<HeaderViewItem?> {
        headerViewItemRelay.asDriver()
    }

    var sortByDriver: Driver<String?> {
        sortByRelay.asDriver()
    }

    var showWarningDriver: Driver<CancellableTitledCaution?> {
        showWarningRelay.asDriver()
    }

    var viewItemsDriver: Driver<[BalanceViewItem]> {
        viewItemsRelay.asDriver()
    }

    var openReceiveSignal: Signal<Wallet> {
        openReceiveRelay.asSignal()
    }

    var openBackupRequiredSignal: Signal<Wallet> {
        openBackupRequiredRelay.asSignal()
    }

    var openCoinPageSignal: Signal<Coin> {
        openCoinPageRelay.asSignal()
    }

    var noConnectionErrorSignal: Signal<()> {
        noConnectionErrorRelay.asSignal()
    }

    var openSyncErrorSignal: Signal<(Wallet, Error)> {
        openSyncErrorRelay.asSignal()
    }

    var showAccountsLostSignal: Signal<()> {
        commonService.accountsLostObservable.asSignal(onErrorJustReturn: ())
    }

    var playHapticSignal: Signal<()> {
        playHapticRelay.asSignal()
    }

    var scrollToTopSignal: Signal<()> {
        scrollToTopRelay.asSignal()
    }

    var sortTypeViewItems: [AlertViewItem] {
        WalletModule.SortType.allCases.map { sortType in
            AlertViewItem(
                    text: sortType.title,
                    selected: sortType == commonService.sortType
            )
        }
    }

    var swipeActionsEnabled: Bool {
        !commonService.watchAccount
    }

    var lastCreatedAccount: Account? {
        commonService.lastCreatedAccount
    }

    var warningUrl: URL? {
        guard let account = commonService.activeAccount else {
            return nil
        }

        return accountRestoreWarningFactory.warningUrl(account: account)
    }

    func onSelectSortType(index: Int) {
        commonService.sortType = WalletModule.SortType.allCases[index]
    }

    func onTapTotalAmount() {
        commonService.toggleBalanceHidden()
        playHapticRelay.accept(())
    }

    func onTapConvertedTotalAmount() {
        service.toggleConversionCoin()
        playHapticRelay.accept(())
    }

    func onTap(item: WalletModule.Item) {
        queue.async {
            if self.expandedItem == item {
                self.expandedItem = nil
                self.syncViewItem(item: item)
            } else {
                let oldExpandedItem = self.expandedItem
                self.expandedItem = item

                if let oldExpandedItem {
                    self.syncViewItem(item: oldExpandedItem)
                }
                self.syncViewItem(item: item)
            }

            self.viewItemsRelay.accept(self.viewItems)
        }
    }

    func onTapReceive(wallet: Wallet) {
        if wallet.account.backedUp || commonService.isCloudBackedUp(account: wallet.account) {
            openReceiveRelay.accept(wallet)
        } else {
            openBackupRequiredRelay.accept(wallet)
        }
    }

    func onTapChart(item: WalletModule.Item) {
        guard let balanceItem = service.balanceItem(item: item), balanceItem.priceItem != nil else {
            return
        }

        openCoinPageRelay.accept(item.coin)
    }

    func onTapFailedIcon(item: WalletModule.Item) {
        guard commonService.isReachable else {
            noConnectionErrorRelay.accept(())
            return
        }

        guard let balanceItem = service.balanceItem(item: item) else {
            return
        }

        guard case let .notSynced(error) = balanceItem.state else {
            return
        }

        guard let wallet = item.wallet else {
            return
        }

        openSyncErrorRelay.accept((wallet, error))
    }

    func onAppear() {
        commonService.notifyAppear()
    }

    func onDisappear() {
        commonService.notifyDisappear()
    }

    func onTriggerRefresh() {
        service.refresh()
    }

    func onDisable(item: WalletModule.Item) {
        if expandedItem == item {
            expandedItem = nil
        }

        service.disable(item: item)
    }

    func onCloseWarning() {
        commonService.didIgnoreAccountWarning()
    }

}

extension WalletViewModel {

    enum DisplayMode {
        case list
        case empty
        case watchEmpty
    }

    struct HeaderViewItem {
        let amount: String?
        let amountExpired: Bool
        let convertedValue: String?
        let convertedValueExpired: Bool
        let watchAccount: Bool
    }

}

import Foundation
import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class WalletViewModel {
    private let service: WalletService
    private let factory: WalletViewItemFactory
    private let disposeBag = DisposeBag()

    private let titleRelay = BehaviorRelay<String?>(value: nil)
    private let displayModeRelay = BehaviorRelay<DisplayMode>(value: .list)
    private let headerViewItemRelay = BehaviorRelay<HeaderViewItem?>(value: nil)
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
    private var expandedWallet: Wallet?

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.wallet-view-model", qos: .userInitiated)

    init(service: WalletService, factory: WalletViewItemFactory) {
        self.service = service
        self.factory = factory

        subscribe(disposeBag, service.activeAccountObservable) { [weak self] in self?.sync(activeAccount: $0) }
        subscribe(disposeBag, service.balanceHiddenObservable) { [weak self] _ in self?.onUpdateBalanceHidden() }
        subscribe(disposeBag, service.totalItemObservable) { [weak self] in self?.sync(totalItem: $0) }
        subscribe(disposeBag, service.itemUpdatedObservable) { [weak self] in self?.syncUpdated(item: $0) }
        subscribe(disposeBag, service.itemsObservable) { [weak self] in self?.sync(items: $0) }
        subscribe(disposeBag, service.sortTypeObservable) { [weak self] in self?.sync(sortType: $0, scrollToTop: true) }
        subscribe(disposeBag, service.balancePrimaryValueObservable) { [weak self] _ in self?.onUpdateBalancePrimaryValue() }

        sync(activeAccount: service.activeAccount)
        sync(totalItem: service.totalItem)
        sync(items: service.items)
        sync(sortType: service.sortType, scrollToTop: false)
    }

    private func sync(activeAccount: Account?) {
        titleRelay.accept(activeAccount?.name)
    }

    private func onUpdateBalanceHidden() {
        sync(items: service.items)
        sync(totalItem: service.totalItem)
    }

    private func onUpdateBalancePrimaryValue() {
        sync(items: service.items)
    }

    private func sync(totalItem: WalletService.TotalItem?) {
        let headerViewItem = totalItem.map { factory.headerViewItem(totalItem: $0, balanceHidden: service.balanceHidden, watchAccount: service.watchAccount) }
        headerViewItemRelay.accept(headerViewItem)
    }

    private func sync(sortType: WalletModule.SortType, scrollToTop: Bool) {
        sortByRelay.accept(sortType.title)

        if scrollToTop {
            scrollToTopRelay.accept(())
        }
    }

    private func syncUpdated(item: WalletService.Item) {
        queue.async {
            guard let index = self.viewItems.firstIndex(where: { $0.wallet == item.wallet }) else {
                return
            }

            self.viewItems[index] = self.viewItem(item: item)
            self.viewItemsRelay.accept(self.viewItems)
        }
    }

    private func sync(items: [WalletService.Item]) {
        queue.async {
            self.viewItems = items.map {
                self.viewItem(item: $0)
            }
            self.viewItemsRelay.accept(self.viewItems)
        }

        displayModeRelay.accept(items.isEmpty ? (service.watchAccount ? .watchEmpty : .empty) : .list)
    }

    private func viewItem(item: WalletService.Item) -> BalanceViewItem {
        factory.viewItem(
                item: item,
                balancePrimaryValue: service.balancePrimaryValue,
                balanceHidden: service.balanceHidden,
                watchAccount: service.watchAccount,
                expanded: item.wallet == expandedWallet
        )
    }

    private func syncViewItem(wallet: Wallet) {
        guard let item = service.item(wallet: wallet), let index = viewItems.firstIndex(where: { $0.wallet == wallet }) else {
            return
        }

        viewItems[index] = viewItem(item: item)
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
        service.accountsLostObservable.asSignal(onErrorJustReturn: ())
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
                    selected: sortType == service.sortType
            )
        }
    }

    var swipeActionsEnabled: Bool {
        !service.watchAccount
    }

    var lastCreatedAccount: Account? {
        service.lastCreatedAccount
    }

    func onSelectSortType(index: Int) {
        service.sortType = WalletModule.SortType.allCases[index]
    }

    func onTapTotalAmount() {
        service.toggleBalanceHidden()
        playHapticRelay.accept(())
    }

    func onTapConvertedTotalAmount() {
        service.toggleConversionCoin()
        playHapticRelay.accept(())
    }

    func onTap(wallet: Wallet) {
        queue.async {
            if self.expandedWallet == wallet {
                self.expandedWallet = nil
                self.syncViewItem(wallet: wallet)
            } else {
                let oldExpandedWallet = self.expandedWallet
                self.expandedWallet = wallet

                if let oldExpandedWallet = oldExpandedWallet {
                    self.syncViewItem(wallet: oldExpandedWallet)
                }
                self.syncViewItem(wallet: wallet)
            }

            self.viewItemsRelay.accept(self.viewItems)
        }
    }

    func onTapReceive(wallet: Wallet) {
        if wallet.account.backedUp {
            openReceiveRelay.accept(wallet)
        } else {
            openBackupRequiredRelay.accept(wallet)
        }
    }

    func onTapChart(wallet: Wallet) {
        guard service.item(wallet: wallet)?.priceItem != nil else {
            return
        }

        openCoinPageRelay.accept(wallet.coin)
    }

    func onTapFailedIcon(wallet: Wallet) {
        guard service.isReachable else {
            noConnectionErrorRelay.accept(())
            return
        }

        guard let item = service.item(wallet: wallet) else {
            return
        }

        guard case let .notSynced(error) = item.state else {
            return
        }

        openSyncErrorRelay.accept((wallet, error))
    }

    func onAppear() {
        service.notifyAppear()
    }

    func onDisappear() {
        service.notifyDisappear()
    }

    func onTriggerRefresh() {
        service.refresh()
    }

    func onDisable(wallet: Wallet) {
        if expandedWallet == wallet {
            expandedWallet = nil
        }

        service.disable(wallet: wallet)
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

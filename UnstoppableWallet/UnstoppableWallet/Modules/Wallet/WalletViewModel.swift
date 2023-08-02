import Foundation
import Combine
import RxSwift
import RxRelay
import RxCocoa
import MarketKit
import HsExtensions

class WalletViewModel {
    private let service: WalletService
    private let factory: WalletViewItemFactory
    private let accountRestoreWarningFactory: AccountRestoreWarningFactory
    private var cancellables = Set<AnyCancellable>()
    private let disposeBag = DisposeBag()

    private let titleRelay = BehaviorRelay<String?>(value: nil)
    private let showWarningRelay = BehaviorRelay<CancellableTitledCaution?>(value: nil)
    private let openReceiveRelay = PublishRelay<Wallet>()
    private let openBackupRequiredRelay = PublishRelay<Wallet>()
    private let openCoinPageRelay = PublishRelay<Coin>()
    private let noConnectionErrorRelay = PublishRelay<()>()
    private let openSyncErrorRelay = PublishRelay<(Wallet, Error)>()
    private let playHapticRelay = PublishRelay<()>()
    private let scrollToTopRelay = PublishRelay<()>()

    @PostPublished private(set) var state: State = .list(viewItems: [])
    @PostPublished private(set) var headerViewItem: HeaderViewItem?
    @Published private(set) var sortBy: String?
    @Published private(set) var controlViewItem: ControlViewItem?
    @Published private(set) var nftVisible: Bool = false

    private var expandedElement: WalletModule.Element?

    private let queue = DispatchQueue(label: "\(AppConfig.label).wallet-view-model", qos: .userInitiated)

    init(service: WalletService, factory: WalletViewItemFactory, accountRestoreWarningFactory: AccountRestoreWarningFactory) {
        self.service = service
        self.factory = factory
        self.accountRestoreWarningFactory = accountRestoreWarningFactory

        subscribe(disposeBag, service.activeAccountObservable) { [weak self] in self?.sync(activeAccount: $0) }
        subscribe(disposeBag, service.balanceHiddenObservable) { [weak self] _ in self?.onUpdateBalanceHidden() }
        subscribe(disposeBag, service.itemUpdatedObservable) { [weak self] in self?.syncUpdated(item: $0) }
        subscribe(disposeBag, service.sortTypeObservable) { [weak self] in self?.sync(sortType: $0, scrollToTop: true) }
        subscribe(disposeBag, service.balancePrimaryValueObservable) { [weak self] _ in self?.onUpdateBalancePrimaryValue() }

        service.$state
                .sink { [weak self] in self?.sync(serviceState: $0) }
                .store(in: &cancellables)

        service.$totalItem
                .sink { [weak self] in self?.sync(totalItem: $0) }
                .store(in: &cancellables)

        sync(activeAccount: service.activeAccount)
        sync(totalItem: service.totalItem)
        sync(sortType: service.sortType, scrollToTop: false)
        _sync(serviceState: service.state)
    }

    private func sync(serviceState: WalletService.State) {
        queue.async {
            self._sync(serviceState: serviceState)
        }
    }

    private func _sync(serviceState: WalletService.State) {
        switch service.state {
        case .noAccount: state = .noAccount
        case .loading: state = .loading
        case .loaded(let items):
            if items.isEmpty, !service.cexAccount {
                state = service.watchAccount ? .watchEmpty : .empty
            } else {
                state = .list(viewItems: items.map { _viewItem(item: $0) })
            }
        case .failed(let reason):
            switch reason {
            case .syncFailed: state = .syncFailed
            case .invalidApiKey: state = .invalidApiKey
            }
        }
    }

    private func sync(activeAccount: Account?) {
        titleRelay.accept(activeAccount?.name)
        nftVisible = activeAccount?.type.supportsNft ?? false

        controlViewItem = activeAccount.map {
            ControlViewItem(watchVisible: $0.watchAccount, coinManagerVisible: !$0.cexAccount && !$0.watchAccount)
        }

        if let account = activeAccount {
            showWarningRelay.accept(accountRestoreWarningFactory.caution(account: account, canIgnoreActiveAccountWarning: true))
        }
    }

    private func onUpdateBalanceHidden() {
        sync(serviceState: service.state)
        sync(totalItem: service.totalItem)
    }

    private func onUpdateBalancePrimaryValue() {
        sync(serviceState: service.state)
    }

    private func sync(totalItem: WalletService.TotalItem?) {
        headerViewItem = totalItem.map { factory.headerViewItem(totalItem: $0, balanceHidden: service.balanceHidden, account: service.activeAccount) }
    }

    private func sync(sortType: WalletModule.SortType, scrollToTop: Bool) {
        sortBy = sortType.title

        if scrollToTop {
            scrollToTopRelay.accept(())
        }
    }

    private func syncUpdated(item: WalletService.Item) {
        queue.async {
            guard case .list(var viewItems) = self.state else {
                return
            }

            guard let index = viewItems.firstIndex(where: { $0.element == item.element }) else {
                return
            }

            viewItems[index] = self._viewItem(item: item)
            self.state = .list(viewItems: viewItems)
        }
    }

    private func _viewItem(item: WalletService.Item) -> BalanceViewItem {
        factory.viewItem(
                item: item,
                balancePrimaryValue: service.balancePrimaryValue,
                balanceHidden: service.balanceHidden,
                expanded: item.element == expandedElement
        )
    }

}

extension WalletViewModel {

    var titleDriver: Driver<String?> {
        titleRelay.asDriver()
    }

    var showWarningDriver: Driver<CancellableTitledCaution?> {
        showWarningRelay.asDriver()
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
        !service.watchAccount && !service.cexAccount
    }

    var lastCreatedAccount: Account? {
        service.lastCreatedAccount
    }

    var warningUrl: URL? {
        guard let account = service.activeAccount else {
            return nil
        }

        return accountRestoreWarningFactory.warningUrl(account: account)
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

    func onTap(element: WalletModule.Element) {
        guard let coin = element.coin else {
            return
        }
        openCoinPageRelay.accept(coin)
    }

    func onTapReceive(wallet: Wallet) {
        if wallet.account.backedUp || service.isCloudBackedUp(account: wallet.account) {
            openReceiveRelay.accept(wallet)
        } else {
            openBackupRequiredRelay.accept(wallet)
        }
    }

    func onTapChart(element: WalletModule.Element) {
        guard let coin = element.coin, let item = service.item(element: element), item.priceItem != nil else {
            return
        }

        openCoinPageRelay.accept(coin)
    }

    func onTapFailedIcon(element: WalletModule.Element) {
        guard service.isReachable else {
            noConnectionErrorRelay.accept(())
            return
        }

        guard let item = service.item(element: element) else {
            return
        }

        guard case let .notSynced(error) = item.state else {
            return
        }

        guard let wallet = element.wallet else {
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

    func onDisable(element: WalletModule.Element) {
        if expandedElement == element {
            expandedElement = nil
        }

        service.disable(element: element)
    }

    func onCloseWarning() {
        service.didIgnoreAccountWarning()
    }

}

extension WalletViewModel {

    enum State: CustomStringConvertible {
        case list(viewItems: [BalanceViewItem])
        case noAccount
        case empty
        case watchEmpty
        case loading
        case syncFailed
        case invalidApiKey

        var description: String {
            switch self {
            case .list(let viewItems): return "list: \(viewItems.count) view items"
            case .noAccount: return "noAccount"
            case .empty: return "empty"
            case .watchEmpty: return "watchEmpty"
            case .loading: return "loading"
            case .syncFailed: return "syncFailed"
            case .invalidApiKey: return "invalidApiKey"
            }
        }
    }

    struct HeaderViewItem {
        let amount: String?
        let amountExpired: Bool
        let convertedValue: String?
        let convertedValueExpired: Bool
        let buttons: [WalletModule.Button: ButtonState]
    }

    struct ControlViewItem {
        let watchVisible: Bool
        let coinManagerVisible: Bool
    }

}

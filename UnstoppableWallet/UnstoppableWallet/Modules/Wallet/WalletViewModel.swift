import Combine
import Foundation
import HsExtensions
import MarketKit
import RxCocoa
import RxRelay
import RxSwift

class WalletViewModel {
    private let service: WalletService
    private let eventHandler: IEventHandler
    private let factory: WalletViewItemFactory
    private let accountRestoreWarningFactory: AccountRestoreWarningFactory
    private var cancellables = Set<AnyCancellable>()
    private let disposeBag = DisposeBag()

    private let titleRelay = BehaviorRelay<String?>(value: nil)
    private let showWarningRelay = BehaviorRelay<CancellableTitledCaution?>(value: nil)
    private let openReceiveRelay = PublishRelay<Void>()
    private let openElementRelay = PublishRelay<WalletModule.Element>()
    private let openBackupRequiredRelay = PublishRelay<Account>()
    private let noConnectionErrorRelay = PublishRelay<Void>()
    private let openSyncErrorRelay = PublishRelay<(Wallet, Error)>()
    private let playHapticRelay = PublishRelay<Void>()
    private let scrollToTopRelay = PublishRelay<Void>()
    private let disableQrScannerRelay = PublishRelay<Bool>()

    @PostPublished private(set) var state: State = .list(viewItems: [])
    @PostPublished private(set) var headerViewItem: WalletModule.HeaderViewItem?
    @Published private(set) var sortBy: String?
    @Published private(set) var controlViewItem: ControlViewItem?
    @Published private(set) var nftVisible: Bool = false
    @Published private(set) var qrScanVisible: Bool = true

    private let queue = DispatchQueue(label: "\(AppConfig.label).wallet-view-model", qos: .userInitiated)

    init(service: WalletService, eventHandler: IEventHandler, factory: WalletViewItemFactory, accountRestoreWarningFactory: AccountRestoreWarningFactory) {
        self.service = service
        self.eventHandler = eventHandler
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

    private func _sync(serviceState _: WalletService.State) {
        switch service.state {
        case .noAccount: state = .noAccount
        case .loading: state = .loading
        case let .loaded(items):
            if items.isEmpty, !service.cexAccount {
                state = service.watchAccount ? .watchEmpty : .empty
            } else {
                state = .list(viewItems: items.map { _viewItem(item: $0) })
            }
        case let .failed(reason):
            switch reason {
            case .syncFailed: state = .syncFailed
            case .invalidApiKey: state = .invalidApiKey
            }
        }

        switch service.state {
        case let .loaded(items): qrScanVisible = !service.watchAccount && !items.isEmpty
        default: qrScanVisible = false
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
            guard case var .list(viewItems) = self.state else {
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
            balanceHidden: service.balanceHidden
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

    var openReceiveSignal: Signal<Void> {
        openReceiveRelay.asSignal()
    }

    var openElementSignal: Signal<WalletModule.Element> {
        openElementRelay.asSignal()
    }

    var openBackupRequiredSignal: Signal<Account> {
        openBackupRequiredRelay.asSignal()
    }

    var noConnectionErrorSignal: Signal<Void> {
        noConnectionErrorRelay.asSignal()
    }

    var openSyncErrorSignal: Signal<(Wallet, Error)> {
        openSyncErrorRelay.asSignal()
    }

    var showAccountsLostSignal: Signal<Void> {
        service.accountsLostObservable.asSignal(onErrorJustReturn: ())
    }

    var playHapticSignal: Signal<Void> {
        playHapticRelay.asSignal()
    }

    var scrollToTopSignal: Signal<Void> {
        scrollToTopRelay.asSignal()
    }

    var disableQrScannerSignal: Signal<Bool> {
        disableQrScannerRelay.asSignal()
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
        openElementRelay.accept(element)
    }

    func onTapReceive() {
        guard let account = service.activeAccount else {
            return
        }
        if account.backedUp || service.isCloudBackedUp(account: account) {
            openReceiveRelay.accept(())
        } else {
            openBackupRequiredRelay.accept(account)
        }
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
        service.disable(element: element)
    }

    func onCloseWarning() {
        service.didIgnoreAccountWarning()
    }

    func process(scanned: String) {
        Task { [weak self, eventHandler] in
            defer {
                self?.disableQrScannerRelay.accept(false)
            }

            do {
                self?.disableQrScannerRelay.accept(true)
                try await eventHandler.handle(event: scanned, eventType: .walletConnectUri)
            } catch {}
        }
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
            case let .list(viewItems): return "list: \(viewItems.count) view items"
            case .noAccount: return "noAccount"
            case .empty: return "empty"
            case .watchEmpty: return "watchEmpty"
            case .loading: return "loading"
            case .syncFailed: return "syncFailed"
            case .invalidApiKey: return "invalidApiKey"
            }
        }
    }

    struct ControlViewItem {
        let watchVisible: Bool
        let coinManagerVisible: Bool
    }
}

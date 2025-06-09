import Combine
import Foundation
import HsExtensions
import MarketKit
import RxCocoa
import RxRelay
import RxSwift

class WalletViewModel {
    private let service: WalletServiceOld
    private let eventHandler: IEventHandler
    private let factory: WalletViewItemFactory
    private let accountRestoreWarningFactory: AccountRestoreWarningFactory
    private var cancellables = Set<AnyCancellable>()
    private let disposeBag = DisposeBag()

    private let titleRelay = BehaviorRelay<String?>(value: nil)
    private let showWarningRelay = BehaviorRelay<CancellableTitledCaution?>(value: nil)
    private let openReceiveRelay = PublishRelay<Void>()
    private let openWalletRelay = PublishRelay<Wallet>()
    private let openBackupRequiredRelay = PublishRelay<Account>()
    private let noConnectionErrorRelay = PublishRelay<Void>()
    private let openSyncErrorRelay = PublishRelay<(Wallet, Error)>()
    private let playHapticRelay = PublishRelay<Void>()
    private let scrollToTopRelay = PublishRelay<Void>()
    private let qrScanningRelay = PublishRelay<Bool>()

    @PostPublished private(set) var state: State = .list(viewItems: [])
    @PostPublished private(set) var headerViewItem: WalletModule.HeaderViewItem?
    @Published private(set) var sortBy: String?
    @Published private(set) var controlViewItem: ControlViewItem?
    @Published private(set) var nftVisible: Bool = false
    @Published private(set) var qrScanVisible: Bool = true

    private let queue = DispatchQueue(label: "\(AppConfig.label).wallet-view-model", qos: .userInitiated)

    init(service: WalletServiceOld, eventHandler: IEventHandler, factory: WalletViewItemFactory, accountRestoreWarningFactory: AccountRestoreWarningFactory) {
        self.service = service
        self.eventHandler = eventHandler
        self.factory = factory
        self.accountRestoreWarningFactory = accountRestoreWarningFactory

        subscribe(disposeBag, service.activeAccountObservable) { [weak self] in self?.sync(activeAccount: $0) }
        subscribe(disposeBag, service.balanceHiddenObservable) { [weak self] _ in self?.onUpdateBalanceHidden() }
        subscribe(disposeBag, service.buttonHiddenObservable) { [weak self] _ in self?.onUpdateButtonHidden() }
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

    private func sync(serviceState: WalletServiceOld.State) {
        queue.async {
            self._sync(serviceState: serviceState)
        }
    }

    private func _sync(serviceState _: WalletServiceOld.State) {
        switch service.state {
        case .noAccount: state = .noAccount
        case let .regular(items):
            state = .list(viewItems: items.map { _viewItem(item: $0) })
        }

        switch service.state {
        case .regular: qrScanVisible = !service.watchAccount
        default: qrScanVisible = false
        }
    }

    private func sync(activeAccount: Account?) {
        titleRelay.accept(activeAccount?.name)
        nftVisible = activeAccount != nil

        controlViewItem = activeAccount.map {
            ControlViewItem(watchVisible: $0.watchAccount, coinManagerVisible: true)
        }

        if let account = activeAccount {
            showWarningRelay.accept(accountRestoreWarningFactory.caution(account: account, canIgnoreActiveAccountWarning: true))
        }
    }

    private func onUpdateBalanceHidden() {
        sync(serviceState: service.state)
        sync(totalItem: service.totalItem)
    }

    private func onUpdateButtonHidden() {
        sync(totalItem: service.totalItem)
    }

    private func onUpdateBalancePrimaryValue() {
        sync(serviceState: service.state)
    }

    private func sync(totalItem: WalletServiceOld.TotalItem?) {
        headerViewItem = totalItem.map { factory.headerViewItem(totalItem: $0, balanceHidden: service.balanceHidden, buttonHidden: service.buttonHidden, account: service.activeAccount) }
    }

    private func sync(sortType: WalletModule.SortType, scrollToTop: Bool) {
        sortBy = sortType.title

        if scrollToTop {
            scrollToTopRelay.accept(())
        }
    }

    private func syncUpdated(item: WalletServiceOld.Item) {
        queue.async {
            guard case var .list(viewItems) = self.state else {
                return
            }

            guard let index = viewItems.firstIndex(where: { $0.wallet == item.wallet }) else {
                return
            }

            viewItems[index] = self._viewItem(item: item)
            self.state = .list(viewItems: viewItems)
        }
    }

    private func _viewItem(item: WalletServiceOld.Item) -> BalanceViewItem {
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

    var openWalletSignal: Signal<Wallet> {
        openWalletRelay.asSignal()
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
        qrScanningRelay.asSignal()
    }

    var sortTypeViewItems: [AlertViewItem] {
        WalletModule.SortType.allCases.map { sortType in
            AlertViewItem(
                text: sortType.title,
                selected: sortType == service.sortType
            )
        }
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
        let sortType = WalletModule.SortType.allCases[index]
        service.sortType = sortType

        stat(page: .balance, event: .switchSortType(sortType: sortType.statSortType))
    }

    func onTapTotalAmount() {
        service.toggleBalanceHidden()
        playHapticRelay.accept(())

        stat(page: .balance, event: .toggleBalanceHidden)
    }

    func onTapConvertedTotalAmount() {
        service.toggleConversionCoin()
        playHapticRelay.accept(())

        stat(page: .balance, event: .toggleConversionCoin)
    }

    func onTap(wallet: Wallet) {
        openWalletRelay.accept(wallet)
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
        service.disable(wallet: wallet)
    }

    func onCloseWarning() {
        service.didIgnoreAccountWarning()
    }

    func process(scanned: String) {
        Task { [weak self, eventHandler] in
            defer {
                self?.qrScanningRelay.accept(false)
            }

            do {
                self?.qrScanningRelay.accept(true)
                try await eventHandler.handle(source: StatPage.balance, event: scanned.trimmingCharacters(in: .whitespacesAndNewlines), eventType: [.walletConnectUri, .address])
            } catch {}
        }
    }
}

extension WalletViewModel {
    enum State: CustomStringConvertible {
        case list(viewItems: [BalanceViewItem])
        case noAccount

        var description: String {
            switch self {
            case let .list(viewItems): return "list: \(viewItems.count) view items"
            case .noAccount: return "noAccount"
            }
        }
    }

    struct ControlViewItem {
        let watchVisible: Bool
        let coinManagerVisible: Bool
    }
}

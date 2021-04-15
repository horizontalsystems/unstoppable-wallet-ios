import RxSwift
import RxRelay
import RxCocoa
import CoinKit

class WalletViewModel {
    private let service: WalletService
    private let rateService: WalletRateService
    private let factory: WalletViewItemFactory
    private let disposeBag = DisposeBag()

    private let titleRelay = BehaviorRelay<String?>(value: nil)
    private let displayModeRelay = BehaviorRelay<DisplayMode>(value: .list)
    private let headerViewItemRelay = BehaviorRelay<HeaderViewItem?>(value: nil)
    private let viewItemsRelay = BehaviorRelay<[BalanceViewItem]>(value: [])
    private let openSortTypeRelay = PublishRelay<()>()
    private let openReceiveRelay = PublishRelay<Wallet>()
    private let openBackupRequiredRelay = PublishRelay<Wallet>()
    private let openCoinPageRelay = PublishRelay<Coin>()
    private let showErrorRelay = PublishRelay<String>()
    private let openSyncErrorRelay = PublishRelay<(Wallet, Error)>()
    private let playHapticRelay = PublishRelay<()>()

    private var viewItems = [BalanceViewItem]()
    private var expandedWallet: Wallet?
    private var balanceHidden: Bool

    init(service: WalletService, rateService: WalletRateService, factory: WalletViewItemFactory) {
        self.service = service
        self.rateService = rateService
        self.factory = factory
        balanceHidden = service.balanceHidden

        subscribe(disposeBag, service.activeAccountObservable) { [weak self] in self?.sync(activeAccount: $0) }
        subscribe(disposeBag, service.balanceHiddenObservable) { [weak self] in self?.sync(balanceHidden: $0) }
        subscribe(disposeBag, service.totalItemObservable) { [weak self] in self?.sync(totalItem: $0) }
        subscribe(disposeBag, service.itemUpdatedObservable) { [weak self] in self?.syncUpdated(item: $0) }
        subscribe(disposeBag, service.itemsObservable) { [weak self] in self?.sync(items: $0) }

        sync(activeAccount: service.activeAccount)
        sync(totalItem: service.totalItem)
        sync(items: service.items)
    }

    private func sync(activeAccount: Account?) {
        titleRelay.accept(activeAccount?.name)
    }

    private func sync(balanceHidden: Bool) {
        self.balanceHidden = balanceHidden

        sync(items: service.items)
        sync(totalItem: service.totalItem)
    }

    private func sync(totalItem: WalletService.TotalItem?) {
        let headerViewItem = totalItem.map { factory.headerViewItem(totalItem: $0, balanceHidden: balanceHidden) }
        headerViewItemRelay.accept(headerViewItem)
    }

    private func syncUpdated(item: WalletService.Item) {
        guard let index = viewItems.firstIndex(where: { $0.wallet == item.wallet }) else {
            return
        }

        viewItems[index] = viewItem(item: item)
        viewItemsRelay.accept(viewItems)
    }

    private func sync(items: [WalletService.Item]) {
        viewItems = items.map { viewItem(item: $0) }
        viewItemsRelay.accept(viewItems)

        displayModeRelay.accept(items.isEmpty ? .empty : .list)
    }

    private func viewItem(item: WalletService.Item) -> BalanceViewItem {
        factory.viewItem(item: item, balanceHidden: balanceHidden, expanded: item.wallet == expandedWallet)
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

    var viewItemsDriver: Driver<[BalanceViewItem]> {
        viewItemsRelay.asDriver()
    }

    var openSortTypeSignal: Signal<()> {
        openSortTypeRelay.asSignal()
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

    var showErrorSignal: Signal<String> {
        showErrorRelay.asSignal()
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

    func onTapTotalAmount() {
        service.toggleBalanceHidden()
        playHapticRelay.accept(())
    }

    func onTapSortBy() {
        openSortTypeRelay.accept(())
    }

    func onTap(wallet: Wallet) {
        if expandedWallet == wallet {
            expandedWallet = nil
            syncViewItem(wallet: wallet)
        } else {
            let oldExpandedWallet = expandedWallet
            expandedWallet = wallet

            if let oldExpandedWallet = oldExpandedWallet {
                syncViewItem(wallet: oldExpandedWallet)
            }
            syncViewItem(wallet: wallet)
        }

        viewItemsRelay.accept(viewItems)
    }

    func onTapReceive(wallet: Wallet) {
        if wallet.account.backedUp {
            openReceiveRelay.accept(wallet)
        } else {
            openBackupRequiredRelay.accept(wallet)
        }
    }

    func onTapChart(wallet: Wallet) {
        guard service.item(wallet: wallet)?.rateItem != nil else {
            return
        }

        openCoinPageRelay.accept(wallet.coin)
    }

    func onTapFailedIcon(wallet: Wallet) {
        guard let item = service.item(wallet: wallet) else {
            return
        }

        guard let state = item.state, case let .notSynced(error) = state else {
            return
        }

        if let appError = error as? AppError, case .noConnection = appError {
            showErrorRelay.accept(appError.smartDescription)
        } else {
            openSyncErrorRelay.accept((wallet, error))
        }
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

}

extension WalletViewModel {

    enum DisplayMode {
        case list
        case empty
    }

    struct HeaderViewItem {
        let amount: String?
        let amountExpired: Bool
    }

}

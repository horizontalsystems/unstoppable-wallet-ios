import Foundation
import Combine
import RxSwift
import RxRelay
import RxCocoa
import MarketKit
import HsExtensions

protocol IWalletTokenListService {
    var state: WalletTokenListService.State { get set }
    var stateUpdatedPublisher: AnyPublisher<WalletTokenListService.State, Never> { get }

    var isReachable: Bool { get }
    var balancePrimaryValueObservable: Observable<BalancePrimaryValue> { get }
    var balancePrimaryValue: BalancePrimaryValue { get }
    var itemUpdatedObservable: Observable<WalletTokenListService.Item> { get }

    func item(element: WalletModule.Element) -> WalletTokenListService.Item?
}

class WalletTokenListViewModel {
    private let service: IWalletTokenListService
    private let factory: WalletTokenListViewItemFactory
    private var cancellables = Set<AnyCancellable>()
    private let disposeBag = DisposeBag()

    let title: String
    let emptyText: String

    private let showWarningRelay = BehaviorRelay<CancellableTitledCaution?>(value: nil)
    private let noConnectionErrorRelay = PublishRelay<()>()
    private let showSyncingRelay = PublishRelay<()>()
    private let selectWalletRelay = PublishRelay<Wallet>()
    private let openSyncErrorRelay = PublishRelay<(Wallet, Error)>()

    @PostPublished private(set) var state: State = .list(viewItems: [])

    private var filter: String?

    private let queue = DispatchQueue(label: "\(AppConfig.label).wallet-tokens-view-model", qos: .userInitiated)

    init(service: IWalletTokenListService, factory: WalletTokenListViewItemFactory, title: String, emptyText: String) {
        self.service = service
        self.factory = factory
        self.title = title
        self.emptyText = emptyText

        subscribe(disposeBag, service.itemUpdatedObservable) { [weak self] in self?.syncUpdated(item: $0) }
        subscribe(disposeBag, service.balancePrimaryValueObservable) { [weak self] _ in self?.onUpdateBalancePrimaryValue() }

        service.stateUpdatedPublisher
                .sink { [weak self] in self?.sync(serviceState: $0) }
                .store(in: &cancellables)

        _sync(serviceState: service.state)
    }

    private func sync(serviceState: WalletTokenListService.State) {
        queue.async {
            self._sync(serviceState: serviceState)
        }
    }

    private func _sync(serviceState: WalletTokenListService.State) {
        switch service.state {
        case .noAccount: state = .noAccount
        case .loading: state = .loading
        case .loaded(let items):
            if items.isEmpty {
                state = .empty
            } else {
                state = .list(viewItems: items.compactMap { _viewItem(item: $0) })
            }
        case .failed(let reason):
            switch reason {
            case .syncFailed: state = .syncFailed
            case .invalidApiKey: state = .invalidApiKey
            }
        }
    }

    private func onUpdateBalancePrimaryValue() {
        sync(serviceState: service.state)
    }

    private func syncUpdated(item: WalletTokenListService.Item) {
        queue.async {
            guard case .list(var viewItems) = self.state else {
                return
            }

            guard let index = viewItems.firstIndex(where: { $0.element == item.element }) else {
                return
            }

            if let item = self._viewItem(item: item) {
                viewItems[index] = item
            }
            self.state = .list(viewItems: viewItems)
        }
    }

    private func _viewItem(item: WalletTokenListService.Item) -> BalanceViewItem? {
        if let filter = filter, !filter.isEmpty {
            if !(item.element.name.localizedCaseInsensitiveContains(filter) || (item.element.coin?.name.localizedCaseInsensitiveContains(filter) ?? false)) {
                return nil
            }
        }
        return factory.viewItem(
                item: item,
                balancePrimaryValue: service.balancePrimaryValue
        )
    }

    private func set(filter: String?) {
        self.filter = filter

        sync(serviceState: service.state)
    }

}

extension WalletTokenListViewModel {

    var showWarningDriver: Driver<CancellableTitledCaution?> {
        showWarningRelay.asDriver()
    }

    var noConnectionErrorSignal: Signal<()> {
        noConnectionErrorRelay.asSignal()
    }

    var showSyncingSignal: Signal<()> {
        showSyncingRelay.asSignal()
    }

    var selectWalletSignal: Signal<Wallet> {
        selectWalletRelay.asSignal()
    }

    var openSyncErrorSignal: Signal<(Wallet, Error)> {
        openSyncErrorRelay.asSignal()
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

    func didSelect(item: BalanceViewItem) {
        if item.topViewItem.failedImageViewVisible {
            onTapFailedIcon(element: item.element)
            return
        }
        if !item.topViewItem.sendEnabled {
            showSyncingRelay.accept(())
            return
        }
        if let wallet = item.element.wallet {
            selectWalletRelay.accept(wallet)
        }
    }

    func onUpdate(filter: String) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.set(filter: filter)
        }
    }

}

extension WalletTokenListViewModel {

    enum State: CustomStringConvertible {
        case list(viewItems: [BalanceViewItem])
        case noAccount
        case empty
        case loading
        case syncFailed
        case invalidApiKey

        var description: String {
            switch self {
            case .list(let viewItems): return "list: \(viewItems.count) view items"
            case .noAccount: return "noAccount"
            case .empty: return "empty"
            case .loading: return "loading"
            case .syncFailed: return "syncFailed"
            case .invalidApiKey: return "invalidApiKey"
            }
        }
    }

}

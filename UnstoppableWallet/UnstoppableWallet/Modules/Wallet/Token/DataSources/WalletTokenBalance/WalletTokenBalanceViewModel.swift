import Combine
import Foundation
import HsExtensions
import MarketKit

class WalletTokenBalanceViewModel {
    private var cancellables = Set<AnyCancellable>()
    private let service: WalletTokenBalanceService
    private let factory: WalletTokenBalanceViewItemFactory

    private let playHapticSubject = PassthroughSubject<Void, Never>()

    @PostPublished private(set) var viewItem: ViewItem?
    @PostPublished private(set) var buttons: [WalletModule.Button: ButtonState] = [:]

    private let openReceiveSubject = PassthroughSubject<Wallet, Never>()
    private let openBackupRequiredSubject = PassthroughSubject<Wallet, Never>()
    private let openCoinPageSubject = PassthroughSubject<Coin, Never>()
    private let noConnectionErrorSubject = PassthroughSubject<Void, Never>()
    private let openSyncErrorSubject = PassthroughSubject<(Wallet, Error), Never>()

    init(service: WalletTokenBalanceService, factory: WalletTokenBalanceViewItemFactory) {
        self.service = service
        self.factory = factory

        service.$item
            .sink { [weak self] in self?.sync(item: $0) }
            .store(in: &cancellables)

        service.itemUpdatedPublisher
            .sink { [weak self] in self?.sync() }
            .store(in: &cancellables)

        service.balanceHiddenPublisher
            .sink { [weak self] _ in self?.sync() }
            .store(in: &cancellables)

        sync(item: service.item)
    }

    private func sync(item: WalletTokenBalanceService.BalanceItem? = nil) {
        let item = item ?? service.item
        viewItem = item.map { factory.headerViewItem(item: $0, balanceHidden: service.balanceHidden) }

        let newButtons = factory.buttons(item: item)
        if buttons != newButtons {
            buttons = newButtons
        }
    }
}

extension WalletTokenBalanceViewModel {
    var playHapticPublisher: AnyPublisher<Void, Never> {
        playHapticSubject.eraseToAnyPublisher()
    }

    var openReceivePublisher: AnyPublisher<Wallet, Never> {
        openReceiveSubject.eraseToAnyPublisher()
    }

    var openBackupRequiredPublisher: AnyPublisher<Wallet, Never> {
        openBackupRequiredSubject.eraseToAnyPublisher()
    }

    var openCoinPagePublisher: AnyPublisher<Coin, Never> {
        openCoinPageSubject.eraseToAnyPublisher()
    }

    var noConnectionErrorPublisher: AnyPublisher<Void, Never> {
        noConnectionErrorSubject.eraseToAnyPublisher()
    }

    var openSyncErrorPublisher: AnyPublisher<(Wallet, Error), Never> {
        openSyncErrorSubject.eraseToAnyPublisher()
    }

    var wallet: Wallet {
        service.wallet
    }

    func onTapAmount() {
        service.toggleBalanceHidden()
        playHapticSubject.send()

        stat(page: .tokenPage, event: .toggleBalanceHidden)
    }

    func onTapReceive() {
        if wallet.account.backedUp || service.isCloudBackedUp() {
            openReceiveSubject.send(wallet)
        } else {
            openBackupRequiredSubject.send(wallet)
        }
    }

    func onTapChart() {
        guard let item = service.item, item.priceItem != nil else {
            return
        }

        openCoinPageSubject.send(service.wallet.coin)
    }

    func onTapFailedIcon() {
        guard service.isReachable else {
            noConnectionErrorSubject.send()
            return
        }

        guard let item = service.item else {
            return
        }

        guard case let .notSynced(error) = item.state else {
            return
        }

        openSyncErrorSubject.send((wallet, error))
    }
}

extension WalletTokenBalanceViewModel {
    enum CustomStateAction {
        case none
        case unshield(Decimal)
    }

    struct BalanceCustomStateViewItem {
        let title: String
        let amountValue: (text: String?, dimmed: Bool)?
        let infoTitle: String
        let infoDescription: String
        let action: CustomStateAction
    }

    struct ViewItem {
        let isMainNet: Bool
        let coin: Coin?
        let placeholderIconName: String?

        let syncSpinnerProgress: Int?
        let indefiniteSearchCircle: Bool
        let failedImageViewVisible: Bool

        let balanceValue: (text: String?, dimmed: Bool)?
        let descriptionValue: (text: String?, dimmed: Bool)?
        let customStates: [BalanceCustomStateViewItem]
    }
}

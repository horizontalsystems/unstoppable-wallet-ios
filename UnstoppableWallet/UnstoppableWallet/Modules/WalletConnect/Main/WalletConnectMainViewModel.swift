import RxSwift
import RxCocoa
import RxRelay
import EthereumKit

class WalletConnectMainViewModel {
    private let scheduler = SerialDispatchQueueScheduler(qos: .userInitiated, internalSerialQueueName: "io.horizontalsystems.unstoppable.wallet_connect_main")

    private let disposeBag = DisposeBag()

    private let service: IWalletConnectMainService

    private let showErrorRelay = PublishRelay<String>()
    private let showSuccessRelay = PublishRelay<()>()
    private let connectingRelay = BehaviorRelay<Bool>(value: false)
    private let cancelVisibleRelay = BehaviorRelay<Bool>(value: false)
    private let connectButtonRelay = BehaviorRelay<ButtonState>(value: .hidden)
    private let reconnectButtonRelay = BehaviorRelay<ButtonState>(value: .hidden)
    private let disconnectButtonRelay = BehaviorRelay<ButtonState>(value: .hidden)
    private let closeVisibleRelay = BehaviorRelay<Bool>(value: false)

    private let activeAccountNameRelay = BehaviorRelay<String?>(value: nil)
    private let appMetaRelay = BehaviorRelay<AppMetaViewItem?>(value: nil)
    private let blockchainsEditableRelay = BehaviorRelay<Bool>(value: false)
    private let blockchainViewItemRelay = BehaviorRelay<[BlockchainViewItem]?>(value: nil)
    private let hintRelay = BehaviorRelay<String?>(value: nil)
    private let statusRelay = BehaviorRelay<Status?>(value: nil)
    private let reloadTableRelay = PublishRelay<()>()

    private let finishRelay = PublishRelay<Void>()

    init(service: IWalletConnectMainService) {
        self.service = service

        subscribe(scheduler, disposeBag, service.errorObservable) { [weak self] in
            self?.showErrorRelay.accept($0.smartDescription)
        }
        subscribe(scheduler, disposeBag, service.stateObservable) { [weak self] state in
            self?.sync(state: state)
        }
        subscribe(scheduler, disposeBag, service.connectionStateObservable) { [weak self] connectionState in
            self?.sync(connectionState: connectionState)
        }
        subscribe(scheduler, disposeBag, service.allowedBlockchainsObservable) { [weak self] allowedBlockchains in
            self?.sync(allowedBlockchains: allowedBlockchains)
        }

        sync()
    }

    private func viewItem(appMetaItem: WalletConnectMainModule.AppMetaItem) -> AppMetaViewItem {
        AppMetaViewItem(
                name: appMetaItem.name,
                url: appMetaItem.url,
                description: appMetaItem.description,
                icon: appMetaItem.icons.last
        )
    }

    private func sync(state: WalletConnectMainModule.State? = nil, connectionState: WalletConnectMainModule.ConnectionState? = nil, allowedBlockchains: [WalletConnectMainModule.Blockchain]? = nil) {
        let state = state ?? service.state
        let connectionState = connectionState ?? service.connectionState
        let allowedBlockchains = allowedBlockchains ?? service.allowedBlockchains

        guard state != .killed else {
            showSuccessRelay.accept(())
            finishRelay.accept(())
            return
        }

        connectingRelay.accept(service.state == .idle)
        cancelVisibleRelay.accept(state != .ready)
        connectButtonRelay.accept(state == .waitingForApproveSession ? (connectionState == .connected ? .enabled : .hidden) : .hidden)
        disconnectButtonRelay.accept(state == .ready ? (connectionState == .connected ? .enabled : .hidden) : .hidden)

        let stateForReconnectButton = state == .waitingForApproveSession || state == .ready
        reconnectButtonRelay.accept(stateForReconnectButton ? (connectionState == .disconnected ? .enabled : .hidden) : .hidden)
        closeVisibleRelay.accept(state == .ready)

        activeAccountNameRelay.accept(service.activeAccountName)
        appMetaRelay.accept(service.appMetaItem.map {
            viewItem(appMetaItem: $0)
        })

        let editable = service.appMetaItem?.editable ?? false
        blockchainsEditableRelay.accept(editable && allowedBlockchains.count > 1)

        blockchainViewItemRelay.accept(
                allowedBlockchains
                        .map { blockchain in
                            BlockchainViewItem(
                                    chainId: blockchain.chainId,
                                    chainTitle: blockchain.evmBlockchain.name,
                                    address: blockchain.address.shortenedAddress,
                                    selected: blockchain.selected
                            )
                        }
        )
        hintRelay.accept(service.hint?.localized)
        statusRelay.accept(status(connectionState: connectionState))

        reloadTableRelay.accept(())
    }

    private func status(connectionState: WalletConnectMainModule.ConnectionState) -> Status? {
        guard service.appMetaItem != nil else {
            return nil
        }

        switch connectionState {
        case .connecting:
            return .connecting
        case .connected:
            return .online
        case .disconnected:
            return .offline
        }
    }

}

extension WalletConnectMainViewModel {

    var showErrorSignal: Signal<String> {
        showErrorRelay.asSignal()
    }

    var showSuccessSignal: Signal<()> {
        showSuccessRelay.asSignal()
    }

    var connectingDriver: Driver<Bool> {
        connectingRelay.asDriver()
    }

    var cancelVisibleDriver: Driver<Bool> {
        cancelVisibleRelay.asDriver()
    }

    var connectButtonDriver: Driver<ButtonState> {
        connectButtonRelay.asDriver()
    }

    var reconnectButtonDriver: Driver<ButtonState> {
        reconnectButtonRelay.asDriver()
    }

    var disconnectButtonDriver: Driver<ButtonState> {
        disconnectButtonRelay.asDriver()
    }

    var closeVisibleDriver: Driver<Bool> {
        closeVisibleRelay.asDriver()
    }

    var activeAccountNameDriver: Driver<String?> {
        activeAccountNameRelay.asDriver()
    }

    var appMetaDriver: Driver<AppMetaViewItem?> {
        appMetaRelay.asDriver()
    }

    var blockchainsEditableDriver: Driver<Bool> {
        blockchainsEditableRelay.asDriver()
    }

    var blockchainViewItemDriver: Driver<[BlockchainViewItem]?> {
        blockchainViewItemRelay.asDriver()
    }

    var statusDriver: Driver<Status?> {
        statusRelay.asDriver()
    }

    var hintDriver: Driver<String?> {
        hintRelay.asDriver()
    }

    var reloadTableSignal: Signal<()> {
        reloadTableRelay.asSignal()
    }

    var finishSignal: Signal<Void> {
        finishRelay.asSignal()
    }

    func onToggle(chainId: Int) {
        service.toggle(chainId: chainId)
    }

    func cancel() {
        if service.connectionState == .connected && service.state == .waitingForApproveSession {
            service.rejectSession()
        } else {
            finishRelay.accept(())
        }
    }

    func reconnect() {
        service.reconnect()
    }

    func connect() {
        service.approveSession()
    }

    func reject() {
        service.rejectSession()
    }

    func disconnect() {
        service.killSession()
    }

    func close() {
        finishRelay.accept(())
    }

}

extension WalletConnectMainViewModel {

    struct AppMetaViewItem {
        let name: String
        let url: String
        let description: String
        let icon: String?
    }

    struct BlockchainViewItem {
        let chainId: Int
        let chainTitle: String?
        let address: String
        let selected: Bool
    }

    enum Status {
        case connecting
        case online
        case offline

        var color: UIColor {
            switch self {
            case .connecting: return .themeLeah
            case .offline: return .themeLucian
            case .online: return .themeRemus
            }
        }

        var title: String {
            switch self {
            case .connecting: return "connecting".localized
            case .offline: return "offline".localized
            case .online: return "online".localized
            }
        }
    }

}

extension WalletConnectMainModule.SessionError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .unsupportedChainId: return "wallet_connect.main.unsupported_chains".localized
        default: return nil
        }
    }

}
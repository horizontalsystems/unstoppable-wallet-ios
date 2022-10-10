import Foundation
import UIKit
import RxSwift
import RxCocoa
import RxRelay
import EvmKit

class WalletConnectMainViewModel {
    private let scheduler = SerialDispatchQueueScheduler(qos: .userInitiated, internalSerialQueueName: "io.horizontalsystems.unstoppable.wallet_connect_main")

    private let service: IWalletConnectMainService
    private let disposeBag = DisposeBag()

    private let showErrorRelay = PublishRelay<String>()
    private let showSuccessRelay = PublishRelay<()>()
    private let showDisconnectRelay = PublishRelay<()>()
    private let connectingRelay = BehaviorRelay<Bool>(value: false)
    private let cancelVisibleRelay = BehaviorRelay<Bool>(value: false)
    private let connectButtonRelay = BehaviorRelay<ButtonState>(value: .hidden)
    private let reconnectButtonRelay = BehaviorRelay<ButtonState>(value: .hidden)
    private let disconnectButtonRelay = BehaviorRelay<ButtonState>(value: .hidden)
    private let closeVisibleRelay = BehaviorRelay<Bool>(value: false)
    private let viewItemRelay = BehaviorRelay<ViewItem?>(value: nil)
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

    private func dAppMetaViewItem(appMetaItem: WalletConnectMainModule.AppMetaItem) -> DAppMetaViewItem {
        DAppMetaViewItem(
                name: appMetaItem.name,
                url: appMetaItem.url,
                icon: appMetaItem.icons.last
        )
    }

    private func sync(state: WalletConnectMainModule.State? = nil, connectionState: WalletConnectMainModule.ConnectionState? = nil, allowedBlockchains: [WalletConnectMainModule.BlockchainItem]? = nil) {
        let state = state ?? service.state
        let connectionState = connectionState ?? service.connectionState
        let allowedBlockchains = allowedBlockchains ?? service.allowedBlockchains

        if case let .killed(reason) = state {
//            showSuccessRelay.accept(())
            switch reason {
            case .rejectProposal: ()
            case .killSession, .rejectSession: showDisconnectRelay.accept(())
            }

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

        var address: String?
        var network: String?
        var blockchains: [BlockchainViewItem]?

        let editable = service.appMetaItem?.editable ?? false

        if editable {
            // v2
            blockchains = allowedBlockchains
                    .map { item in
                        BlockchainViewItem(
                                chainId: item.chainId,
                                chainTitle: item.blockchain.name,
                                address: item.address.shortened,
                                selected: item.selected
                        )
                    }
        } else {
            // v1
            if let blockchainItem = allowedBlockchains.first(where: { $0.selected }) {
                address = blockchainItem.address.shortened
                network = blockchainItem.blockchain.name
            }
        }

        let viewItem = ViewItem(
                dAppMeta: service.appMetaItem.map { dAppMetaViewItem(appMetaItem: $0) },
                status: status(connectionState: connectionState),
                activeAccountName: service.activeAccountName,
                address: address,
                network: network,
                networkEditable: state == .waitingForApproveSession,
                blockchains: blockchains,
                hint: service.hint
        )

        viewItemRelay.accept(viewItem)
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

    var showDisconnectSignal: Signal<()> {
        showDisconnectRelay.asSignal()
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

    var viewItemDriver: Driver<ViewItem?> {
        viewItemRelay.asDriver()
    }

    var finishSignal: Signal<Void> {
        finishRelay.asSignal()
    }

    var blockchainSelectorViewItems: [BlockchainSelectorViewItem] {
        service.allowedBlockchains.map { item in
            BlockchainSelectorViewItem(
                    chainId: item.chainId,
                    title: item.blockchain.name,
                    imageUrl: item.blockchain.type.imageUrl,
                    selected: item.selected
            )
        }
    }

    func onSelect(chainId: Int) {
        service.select(chainId: chainId)
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

    struct ViewItem {
        let dAppMeta: DAppMetaViewItem?
        let status: Status?
        let activeAccountName: String?

        // v1
        let address: String?
        let network: String?
        let networkEditable: Bool

        // v2
        let blockchains: [BlockchainViewItem]?

        let hint: String?
    }

    struct DAppMetaViewItem {
        let name: String
        let url: String
        let icon: String?
    }

    struct BlockchainViewItem {
        let chainId: Int
        let chainTitle: String?
        let address: String
        let selected: Bool
    }

    struct BlockchainSelectorViewItem {
        let chainId: Int
        let title: String
        let imageUrl: String
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
        case .noAnySupportedChainId: return "wallet_connect.main.no_any_supported_chains".localized
        case .unsupportedChainId: return "wallet_connect.main.unsupported_chains".localized
        default: return nil
        }
    }

}
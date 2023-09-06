import Foundation
import RxSwift
import RxRelay
import RxCocoa
import WalletConnectSign
import WalletConnectPairing

class WalletConnectListViewModel {
    private let service: WalletConnectListService
    private let disposeBag = DisposeBag()

    private let newConnectionErrorRelay = PublishRelay<String>()

    private let showWalletConnectSessionRelay = PublishRelay<WalletConnectSign.Session>()
    private let showWalletConnectValidatedRelay = PublishRelay<String>()
    private let showWaitingForSessionRelay = PublishRelay<()>()
    private let hideWaitingForSessionRelay = PublishRelay<()>()
    private let showAttentionRelay = PublishRelay<String>()
    private let disableNewConnectionRelay = PublishRelay<Bool>()

    private let viewItemsRelay = BehaviorRelay<[WalletConnectListViewModel.ViewItem]>(value: [])
    private let pairingCountRelay = BehaviorRelay<Int>(value: 0)
    private let showDisconnectingRelay = PublishRelay<()>()
    private let showSuccessRelay = PublishRelay<()>()

    init(service: WalletConnectListService) {
        self.service = service

        subscribe(disposeBag, service.validateResultObservable) { [weak self] in self?.validate(result: $0) }
        subscribe(disposeBag, service.pairingResultObservable) { [weak self] in self?.pairing(result: $0) }
        subscribe(disposeBag, service.proposalReceivedObservable) { [weak self] in self?.proposalReceived() }
        subscribe(disposeBag, service.proposalTimeOutObservable) { [weak self] in self?.proposalWaitingTimeOut() }
        subscribe(disposeBag, service.connectionErrorObservable) { [weak self] in self?.show(connectionError: $0) }

        subscribe(disposeBag, service.itemsObservable) { [weak self] in self?.sync(items: $0) }
        subscribe(disposeBag, service.pendingRequestsObservable) { [weak self] in self?.sync(pendingRequests: $0) }
        subscribe(disposeBag, service.pairingsObservable) { [weak self] in self?.sync(pairings: $0) }
        subscribe(disposeBag, service.showSessionObservable) { [weak self] in self?.show(session: $0) }
        subscribe(disposeBag, service.sessionKillingObservable) { [weak self] in self?.sync(sessionKillingState: $0) }

        sync(items: service.items)
        sync(pendingRequests: service.pendingRequests)
        sync(pairings: service.pairings)
    }

    private func sync(items: [WalletConnectListService.Item]) {
        let viewItems = items.map {
            let description = $0.blockchains.map { $0.shortName }.joined(separator: ", ")

            var badge: String?
            if $0.requestCount != 0 {
                badge = "\($0.requestCount)"
            }

            return WalletConnectListViewModel.ViewItem(
                    id: $0.id,
                    title: ($0.appName != "") ? $0.appName : "Unnamed",
                    description: description,
                    badge: badge,
                    imageUrl: $0.appIcons.last
            )
        }

        viewItemsRelay.accept(viewItems)
    }

    private func sync(pairings: [WalletConnectPairing.Pairing]) {
        pairingCountRelay.accept(pairings.count)
    }

    private func sync(pendingRequests: [WalletConnectSign.Request]) {
        sync(items: service.items)
    }

    private func sync(sessionKillingState: WalletConnectListService.SessionKillingState) {
        switch sessionKillingState {
        case .processing: showDisconnectingRelay.accept(())
        case .completed: showSuccessRelay.accept(())        // don't needed different text
        case .removedOnly: showSuccessRelay.accept(())      // app just remove peerId from database
        }
    }

    private func show(session: WalletConnectSign.Session) {
        showWalletConnectSessionRelay.accept(session)
    }

    private func validate(result: Result<String, Error>) {
        switch result {
        case .success(let uri): showWalletConnectValidatedRelay.accept(uri)
        case .failure(let error): newConnectionErrorRelay.accept(error.smartDescription)
        }
    }

    private func pairing(result: Result<(), Error>) {
        switch result {
        case .success:
            showWaitingForSessionRelay.accept(())
            disableNewConnectionRelay.accept(true)
        case .failure(let error): showAttentionRelay.accept(error.smartDescription)
        }
    }

    private func proposalReceived() {
        hideWaitingForSessionRelay.accept(())
        disableNewConnectionRelay.accept(false)
    }

    private func proposalWaitingTimeOut() {
        showAttentionRelay.accept("alert.try_again".localized)
        disableNewConnectionRelay.accept(false)
    }

    private func show(connectionError: Error) {
        newConnectionErrorRelay.accept(connectionError.smartDescription)
    }

}

extension WalletConnectListViewModel {

    var isWaitingForSession: Bool {
        service.isWaitingForSession
    }

    var showWalletConnectSessionSignal: Signal<WalletConnectSign.Session> {
        showWalletConnectSessionRelay.asSignal()
    }

    var viewItemsDriver: Driver<[WalletConnectListViewModel.ViewItem]> {
        viewItemsRelay.asDriver()
    }

    var pairingCountDriver: Driver<Int> {
        pairingCountRelay.asDriver()
    }

    var showDisconnectingSignal: Signal<()> {
        showDisconnectingRelay.asSignal()
    }

    var showSuccessSignal: Signal<()> {
        showSuccessRelay.asSignal()
    }

    // NewConnection section
    var emptyList: Bool {
        service.emptySessionList && service.emptyPairingList
    }

    var showWalletConnectValidatedSignal: Signal<String> {
        showWalletConnectValidatedRelay.asSignal()
    }

    var showWaitingForSessionSignal: Signal<()> {
        showWaitingForSessionRelay.asSignal()
    }

    var hideWaitingForSessionSignal: Signal<()> {
        hideWaitingForSessionRelay.asSignal()
    }

    var disableNewConnectionSignal: Signal<Bool> {
        disableNewConnectionRelay.asSignal()
    }

    var showErrorSignal: Signal<String> {
        showAttentionRelay.asSignal()
    }

    var newConnectionErrorSignal: Signal<String> {
        newConnectionErrorRelay.asSignal()
    }

    func didScan(string: String) {
        service.connect(uri: string)
    }

    func pair(validUri: String) {
        service.pair(validUri: validUri)
    }

    // Manage connections
    func showSession(id: Int) {
        service.showSession(id: id)
    }

    func kill(id: Int) {
        service.kill(id: id)
    }

}

extension WalletConnectListViewModel {

    class ViewItem {
        let id: Int
        let title: String
        let description: String
        let badge: String?
        let imageUrl: String?

        init(id: Int, title: String, description: String, badge: String? = nil, imageUrl: String?) {
            self.id = id
            self.title = title
            self.description = description
            self.badge = badge
            self.imageUrl = imageUrl
        }
    }

}

extension WalletConnectUriHandler.ConnectionError : LocalizedError {

    var errorDescription: String? {
        switch self {
        case .wrongUri: return "wallet_connect.error.invalid_url".localized
        }
    }

}

import Foundation
import RxSwift
import RxRelay
import RxCocoa

class WalletConnectListViewModel {
    private let service: WalletConnectListService
    private let disposeBag = DisposeBag()

    private let newConnectionErrorRelay = PublishRelay<String>()
    private let showWalletConnectV1MainServiceRelay = PublishRelay<WalletConnectV1MainService>()
    private let showWalletConnectV2ValidatedRelay = PublishRelay<String>()
    private let showWaitingForSessionRelay = PublishRelay<()>()
    private let hideWaitingForSessionRelay = PublishRelay<()>()
    private let showAttentionRelay = PublishRelay<String>()
    private let disableNewConnectionRelay = PublishRelay<Bool>()
    private let showWalletConnectV1SessionRelay = PublishRelay<WalletConnectSession>()

    init(service: WalletConnectListService) {
        self.service = service

        subscribe(disposeBag, service.createServiceV1Observable) { [weak self] in self?.show(service: $0) }
        subscribe(disposeBag, service.validateV2ResultObservable) { [weak self] in self?.validateV2(result: $0) }
        subscribe(disposeBag, service.pairingV2ResultObservable) { [weak self] in self?.pairingV2(result: $0) }
        subscribe(disposeBag, service.proposalV2ReceivedObservable) { [weak self] in self?.proposalReceived() }
        subscribe(disposeBag, service.proposalV2timeOutObservable) { [weak self] in self?.proposalWaitingTimeOut() }
        subscribe(disposeBag, service.connectionErrorObservable) { [weak self] in self?.show(connectionError: $0) }
    }

    private func show(service: WalletConnectV1MainService) {
        showWalletConnectV1MainServiceRelay.accept(service)
    }

    private func validateV2(result: Result<String, Error>) {
        switch result {
        case .success(let uri): showWalletConnectV2ValidatedRelay.accept(uri)
        case .failure(let error): newConnectionErrorRelay.accept(error.smartDescription)
        }
    }

    private func pairingV2(result: Result<(), Error>) {
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

    // NewConnection section
    var emptyList: Bool {
        service.emptySessionList && service.emptyPairingList
    }

    var showWalletConnectMainModuleSignal: Signal<WalletConnectV1MainService> {
        showWalletConnectV1MainServiceRelay.asSignal()
    }

    var showWalletConnectV2ValidatedSignal: Signal<String> {
        showWalletConnectV2ValidatedRelay.asSignal()
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

    func pairV2(validUri: String) {
        service.pairV2(validUri: validUri)
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

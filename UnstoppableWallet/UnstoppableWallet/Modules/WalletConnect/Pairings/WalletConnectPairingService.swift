import RxSwift
import RxRelay
import WalletConnectPairing

class WalletConnectPairingService {
    private var disposeBag = DisposeBag()

    private let sessionManager: WalletConnectSessionManager

    private let itemsRelay = PublishRelay<[Item]>()
    private(set) var items = [Item]() {
        didSet {
            itemsRelay.accept(items)
        }
    }

    private let pairingKillingRelay = PublishRelay<PairingKillingState>()

    init(sessionManager: WalletConnectSessionManager) {
        self.sessionManager = sessionManager

        subscribe(disposeBag, sessionManager.pairingsObservable) { [weak self] _ in self?.syncPairings() }
        syncPairings()
    }

    private func syncPairings() {
        items = sessionManager.pairings.map { (pairing: WalletConnectPairing.Pairing) in
            let appName = pairing.peer?.name ?? "Unnamed"
            return Item(topic: pairing.topic,
                    appName: appName,
                    appUrl: pairing.peer?.url,
                    appDescription: pairing.peer?.description,
                    appIcons: pairing.peer?.icons ?? []
            )
        }
    }

}

extension WalletConnectPairingService {

    var itemsObservable: Observable<[Item]> {
        itemsRelay.asObservable()
    }

    var pairingKillingObservable: Observable<PairingKillingState> {
        pairingKillingRelay.asObservable()
    }

    func disconnect(topic: String) {
        disposeBag = DisposeBag()
        pairingKillingRelay.accept(.processing)

        sessionManager.disconnectPairing(topic: topic)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
            .subscribe(onSuccess: { [weak self] _ in
                self?.pairingKillingRelay.accept(.completed)
                self?.syncPairings()
            }, onError: { [weak self] error in
                self?.pairingKillingRelay.accept(.failed)
                self?.syncPairings()
            })
            .disposed(by: disposeBag)
    }

    func disconnectAll() {
        let singles: [Single<Bool>] = sessionManager.pairings.map {  pairing in
            sessionManager
                    .disconnectPairing(topic: pairing.topic)
                    .map { _ in true }
                    .catchErrorJustReturn(false)
        }

        Single.zip(singles)
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onSuccess: { [weak self] results in
                    self?.pairingKillingRelay.accept(results.first(where: { $0 == false }) == nil ? .completed : .failed)
                    self?.syncPairings()
                })
                .disposed(by: disposeBag)
    }

}

extension WalletConnectPairingService {

    enum PairingKillingState {
        case processing
        case completed
        case failed
    }

    struct Item {
        let topic: String

        let appName: String
        let appUrl: String?
        let appDescription: String?
        let appIcons: [String]
    }

}

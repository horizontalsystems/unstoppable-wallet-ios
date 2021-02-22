import RxSwift
import RxRelay
import RxCocoa

class WalletConnectListViewModel {
    private let service: WalletConnectListService
    private let disposeBag = DisposeBag()

    private let viewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])

    init(service: WalletConnectListService) {
        self.service = service

        subscribe(disposeBag, service.sessionsObservable) { [weak self] in self?.sync(sessions: $0) }

        sync(sessions: service.sessions)
    }

    private func sync(sessions: [WalletConnectSession]) {
        print(sessions.first?.peerId)
        let viewItems = sessions.map { session in
            ViewItem(
                    session: session,
                    title: session.peerMeta.name,
                    imageUrl: session.peerMeta.icons.first,
                    address: ""
            )
        }

        viewItemsRelay.accept(viewItems)
    }

}

extension WalletConnectListViewModel {

    var viewItemsDriver: Driver<[ViewItem]> {
        viewItemsRelay.asDriver()
    }

}

extension WalletConnectListViewModel {

    struct ViewItem {
        let session: WalletConnectSession
        let title: String
        let imageUrl: String?
        let address: String
    }

}

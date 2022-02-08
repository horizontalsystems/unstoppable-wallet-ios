import RxSwift
import RxRelay
import RxCocoa
import WalletConnectV1

class WalletConnectV1XMainRequestViewModel {
    private let disposeBag = DisposeBag()
    let service: WalletConnectV1XMainService

    private let openRequestRelay = PublishRelay<WalletConnectRequest>()

    init(service: WalletConnectV1XMainService) {
        self.service = service

        subscribe(disposeBag, service.requestObservable) { [weak self] in self?.openRequestRelay.accept($0) }
    }

}

extension WalletConnectV1XMainRequestViewModel {

    var openRequestSignal: Signal<WalletConnectRequest> {
        openRequestRelay.asSignal()
    }

}
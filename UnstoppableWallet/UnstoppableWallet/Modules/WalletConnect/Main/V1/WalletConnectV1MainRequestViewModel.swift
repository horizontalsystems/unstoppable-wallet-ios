import RxSwift
import RxRelay
import RxCocoa
import WalletConnectV1

class WalletConnectV1MainRequestViewModel {
    private let disposeBag = DisposeBag()
    let service: WalletConnectV1MainService

    private let openRequestRelay = PublishRelay<WalletConnectRequest>()

    init(service: WalletConnectV1MainService) {
        self.service = service

        subscribe(disposeBag, service.requestObservable) { [weak self] in self?.openRequestRelay.accept($0) }
    }

}

extension WalletConnectV1MainRequestViewModel {

    var openRequestSignal: Signal<WalletConnectRequest> {
        openRequestRelay.asSignal()
    }

}
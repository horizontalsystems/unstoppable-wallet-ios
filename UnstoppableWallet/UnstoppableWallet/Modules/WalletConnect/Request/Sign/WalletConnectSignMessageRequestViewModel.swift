import RxSwift
import RxRelay
import RxCocoa

class WalletConnectSignMessageRequestViewModel {
    private let service: WalletConnectSignMessageRequestService

    private let errorRelay = PublishRelay<Error>()
    private let dismissRelay = PublishRelay<()>()

    init(service: WalletConnectSignMessageRequestService) {
        self.service = service
    }

}

extension WalletConnectSignMessageRequestViewModel {

    var errorSignal: Signal<Error> {
        errorRelay.asSignal()
    }

    var dismissSignal: Signal<()> {
        dismissRelay.asSignal()
    }

    var message: String {
        service.message
    }

    var domain: String? {
        service.domain
    }

    var dAppName: String? {
        service.dAppName
    }

    func onSign() {
        do {
            try service.sign()
            dismissRelay.accept(())
        } catch {
            errorRelay.accept(error)
        }
    }

    func onReject() {
        service.reject()
        dismissRelay.accept(())
    }

}

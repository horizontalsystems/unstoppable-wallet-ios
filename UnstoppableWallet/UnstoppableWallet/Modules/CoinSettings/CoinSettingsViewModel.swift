import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class CoinSettingsViewModel {
    private let service: CoinSettingsService
    private let disposeBag = DisposeBag()

    private let openRequestRelay = PublishRelay<CoinSettingsService.Request>()
    private var currentRequest: CoinSettingsService.Request?

    init(service: CoinSettingsService) {
        self.service = service

        subscribe(disposeBag, service.requestObservable) { [weak self] in self?.handle(request: $0) }
    }

    private func handle(request: CoinSettingsService.Request) {
        currentRequest = request
        openRequestRelay.accept(request)
    }

}

extension CoinSettingsViewModel {

    var openRequestSignal: Signal<CoinSettingsService.Request> {
        openRequestRelay.asSignal()
    }

    func onApprove(coinSettingsArray: [CoinSettings]) {
        guard let request = currentRequest else {
            return
        }

        service.approve(coinSettingsArray: coinSettingsArray, token: request.token)
    }

    func onCancelApprove() {
        guard let request = currentRequest else {
            return
        }

        service.cancel(token: request.token)
    }

}

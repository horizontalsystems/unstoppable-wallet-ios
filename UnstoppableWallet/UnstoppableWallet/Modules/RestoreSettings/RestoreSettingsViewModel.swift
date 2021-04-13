import RxSwift
import RxRelay
import RxCocoa
import CoinKit

class RestoreSettingsViewModel {
    private let service: RestoreSettingsService
    private let disposeBag = DisposeBag()

    private let openBirthdayAlertRelay = PublishRelay<Coin>()

    private var currentRequest: RestoreSettingsService.Request?

    init(service: RestoreSettingsService) {
        self.service = service

        subscribe(disposeBag, service.requestObservable) { [weak self] in self?.handle(request: $0) }
    }

    private func handle(request: RestoreSettingsService.Request) {
        currentRequest = request

        switch request.type {
        case .birthdayHeight:
            openBirthdayAlertRelay.accept(request.coin)
        }
    }

}

extension RestoreSettingsViewModel {

    var openBirthdayAlertSignal: Signal<Coin> {
        openBirthdayAlertRelay.asSignal()
    }

    func onEnter(birthdayHeight: Int) {
        guard let request = currentRequest else {
            return
        }

        switch request.type {
        case .birthdayHeight:
            service.enter(birthdayHeight: birthdayHeight, coin: request.coin)
        }
    }

    func onCancelEnterBirthdayHeight() {
        guard let request = currentRequest else {
            return
        }

        service.cancel(coin: request.coin)
    }

}

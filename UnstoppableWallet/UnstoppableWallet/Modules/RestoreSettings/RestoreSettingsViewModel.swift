import RxSwift
import RxRelay
import RxCocoa
import CoinKit

class RestoreSettingsViewModel {
    private let service: RestoreSettingsService
    private let disposeBag = DisposeBag()

    private let openBirthdayAlertRelay = PublishRelay<String>()

    private var currentRequest: RestoreSettingsService.Request?

    init(service: RestoreSettingsService) {
        self.service = service

        subscribe(disposeBag, service.requestObservable) { [weak self] in self?.handle(request: $0) }
    }

    private func handle(request: RestoreSettingsService.Request) {
        currentRequest = request

        switch request.type {
        case .birthdayHeight:
            openBirthdayAlertRelay.accept(request.coin.title)
        }
    }

}

extension RestoreSettingsViewModel {

    var openBirthdayAlertSignal: Signal<String> {
        openBirthdayAlertRelay.asSignal()
    }

    func onEnter(birthdayHeight: String?) {
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

import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class RestoreSettingsViewModel {
    private let service: RestoreSettingsService
    private let disposeBag = DisposeBag()

    private let openBirthdayAlertRelay = PublishRelay<PlatformCoin>()

    private var currentRequest: RestoreSettingsService.Request?

    init(service: RestoreSettingsService) {
        self.service = service

        subscribe(disposeBag, service.requestObservable) { [weak self] in self?.handle(request: $0) }
    }

    private func handle(request: RestoreSettingsService.Request) {
        currentRequest = request

        switch request.type {
        case .birthdayHeight:
            openBirthdayAlertRelay.accept(request.platformCoin)
        }
    }

}

extension RestoreSettingsViewModel {

    var openBirthdayAlertSignal: Signal<PlatformCoin> {
        openBirthdayAlertRelay.asSignal()
    }

    func onEnter(birthdayHeight: Int) {
        guard let request = currentRequest else {
            return
        }

        switch request.type {
        case .birthdayHeight:
            service.enter(birthdayHeight: birthdayHeight, platformCoin: request.platformCoin)
        }
    }

    func onCancelEnterBirthdayHeight() {
        guard let request = currentRequest else {
            return
        }

        service.cancel(platformCoin: request.platformCoin)
    }

}

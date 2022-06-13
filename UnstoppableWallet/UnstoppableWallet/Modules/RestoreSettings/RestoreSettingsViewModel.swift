import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class RestoreSettingsViewModel {
    private let service: RestoreSettingsService
    private let disposeBag = DisposeBag()

    private let openBirthdayAlertRelay = PublishRelay<Token>()

    private var currentRequest: RestoreSettingsService.Request?

    init(service: RestoreSettingsService) {
        self.service = service

        subscribe(disposeBag, service.requestObservable) { [weak self] in self?.handle(request: $0) }
    }

    private func handle(request: RestoreSettingsService.Request) {
        currentRequest = request

        switch request.type {
        case .birthdayHeight:
            openBirthdayAlertRelay.accept(request.token)
        }
    }

}

extension RestoreSettingsViewModel {

    var openBirthdayAlertSignal: Signal<Token> {
        openBirthdayAlertRelay.asSignal()
    }

    func onEnter(birthdayHeight: Int?) {
        guard let request = currentRequest else {
            return
        }

        switch request.type {
        case .birthdayHeight:
            service.enter(birthdayHeight: birthdayHeight, token: request.token)
        }
    }

    func onCancelEnterBirthdayHeight() {
        guard let request = currentRequest else {
            return
        }

        service.cancel(token: request.token)
    }

}

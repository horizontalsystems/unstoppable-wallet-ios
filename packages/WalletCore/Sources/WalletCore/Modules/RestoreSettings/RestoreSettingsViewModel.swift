import Combine
import MarketKit

class RestoreSettingsViewModel {
    private let service: RestoreSettingsService
    private var cancellables = Set<AnyCancellable>()

    private let openBirthdayAlertSubject = PassthroughSubject<Token, Never>()
    private let openNearAccountSubject = PassthroughSubject<AccountType, Never>()

    private var currentRequest: RestoreSettingsService.Request?

    init(service: RestoreSettingsService) {
        self.service = service

        service.requestPublisher
            .sink { [weak self] in self?.handle(request: $0) }
            .store(in: &cancellables)
    }

    private func handle(request: RestoreSettingsService.Request) {
        currentRequest = request

        switch request.type {
        case .birthdayHeight:
            openBirthdayAlertSubject.send(request.token)
        case let .nearAccount(accountType):
            openNearAccountSubject.send(accountType)
        }
    }
}

extension RestoreSettingsViewModel {
    var openBirthdayAlertPublisher: AnyPublisher<Token, Never> {
        openBirthdayAlertSubject.eraseToAnyPublisher()
    }

    var openNearAccountPublisher: AnyPublisher<AccountType, Never> {
        openNearAccountSubject.eraseToAnyPublisher()
    }

    func onEnter(birthdayHeight: Int?) {
        guard let request = currentRequest else {
            return
        }

        switch request.type {
        case .birthdayHeight:
            service.enter(birthdayHeight: birthdayHeight, token: request.token)
        case .nearAccount:
            ()
        }
    }

    func onEnter(settings: RestoreSettings) {
        guard let request = currentRequest else {
            return
        }

        service.enter(settings: settings, token: request.token)
    }

    func onCancelEnterBirthdayHeight() {
        guard let request = currentRequest else {
            return
        }

        service.cancel(token: request.token)
    }
}

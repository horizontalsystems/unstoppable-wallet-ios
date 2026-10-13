import Combine
import MarketKit

class RestoreSettingsViewModel {
    private let service: RestoreSettingsService
    private var cancellables = Set<AnyCancellable>()

    private let openRequestSubject = PassthroughSubject<RestoreSettingsService.Request, Never>()

    private var currentRequest: RestoreSettingsService.Request?

    init(service: RestoreSettingsService) {
        self.service = service

        service.requestPublisher
            .sink { [weak self] in self?.handle(request: $0) }
            .store(in: &cancellables)
    }

    private func handle(request: RestoreSettingsService.Request) {
        currentRequest = request
        openRequestSubject.send(request)
    }
}

extension RestoreSettingsViewModel {
    var openRequestPublisher: AnyPublisher<RestoreSettingsService.Request, Never> {
        openRequestSubject.eraseToAnyPublisher()
    }

    func onEnter(settings: RestoreSettings) {
        guard let request = currentRequest else {
            return
        }

        service.enter(settings: settings, token: request.token)
    }

    func onCancel() {
        guard let request = currentRequest else {
            return
        }

        service.cancel(token: request.token)
    }
}

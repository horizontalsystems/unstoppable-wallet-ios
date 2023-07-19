import Combine
import HsExtensions

class PersonalSupportViewModel {
    private let service: PersonalSupportService

    @Published private(set) var requestButtonState: AsyncActionButtonState = .enabled

    init(service: PersonalSupportService) {
        self.service = service
    }
}

extension PersonalSupportViewModel {

    var successPublisher: AnyPublisher<Void, Never> {
        service.successPublisher
            .handleEvents(receiveOutput: { [weak self] in self?.requestButtonState = .disabled })
            .eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<String, Never> {
        service.errorPublisher
            .handleEvents(receiveOutput: { [weak self] _ in self?.requestButtonState = .enabled })
            .map { _ in "settings.personal_support.failed".localized }
            .eraseToAnyPublisher()
    }

    func onChanged(username: String?) {
        service.set(username: username?.trimmingCharacters(in: .whitespaces))
    }

    func onTapRequest() {
        requestButtonState = .spinner
        service.request()
    }

}

import Combine
import HsExtensions

class PersonalSupportViewModel {
    private let service: PersonalSupportService
    private var cancellables = Set<AnyCancellable>()

    private let hiddenRequestButtonSubject = CurrentValueSubject<Bool, Never>(false)
    private let enabledRequestButtonSubject = CurrentValueSubject<Bool, Never>(false)
    private let hiddenRequestingButtonSubject = CurrentValueSubject<Bool, Never>(false)
    private let showRequestedScreenSubject = CurrentValueSubject<Bool, Never>(true)

    init(service: PersonalSupportService) {
        self.service = service

        service.$requestButtonState
                .sink { [weak self] state in
                    self?.sync(state: state)
                }
                .store(in: &cancellables)

        subscribe(&cancellables, service.$requested) { [weak self] in self?.showRequestedScreenSubject.send($0) }

        sync(state: service.requestButtonState)
        showRequestedScreenSubject.send(service.requested)
    }

    private func sync(state: AsyncActionButtonState) {
        var requestButtonEnabled = false
        var requestButtonHidden = false
        var requestingButtonHidden = false
        switch state {
        case .enabled:
            requestButtonEnabled = true
            requestingButtonHidden = true
        case .spinner:
            requestButtonHidden = true
        case .disabled:
            requestingButtonHidden = true
        }
        hiddenRequestButtonSubject.send(requestButtonHidden)
        enabledRequestButtonSubject.send(requestButtonEnabled)
        hiddenRequestingButtonSubject.send(requestingButtonHidden)
    }

}

extension PersonalSupportViewModel {

    var showRequestedScreenPublisher: AnyPublisher<Bool, Never> {
        showRequestedScreenSubject.eraseToAnyPublisher()
    }

    var hiddenRequestButtonPublisher: AnyPublisher<Bool, Never> {
        hiddenRequestButtonSubject.eraseToAnyPublisher()
    }

    var enabledRequestButtonPublisher: AnyPublisher<Bool, Never> {
        enabledRequestButtonSubject.eraseToAnyPublisher()
    }

    var hiddenRequestingButtonPublisher: AnyPublisher<Bool, Never> {
        hiddenRequestingButtonSubject.eraseToAnyPublisher()
    }

    var successPublisher: AnyPublisher<Void, Never> {
        service.successPublisher.eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<String, Never> {
        service.errorPublisher
            .map { _ in "settings.personal_support.failed".localized }
            .eraseToAnyPublisher()
    }

    func onChanged(username: String?) {
        service.set(username: username?.trimmingCharacters(in: .whitespaces))
    }

    func onTapRequest() {
        service.request()
    }

    func onTapNewRequest() {
        service.newRequest()
    }

}

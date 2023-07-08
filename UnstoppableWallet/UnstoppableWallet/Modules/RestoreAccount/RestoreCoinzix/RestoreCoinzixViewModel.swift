import Combine

class RestoreCoinzixViewModel {
    private let service: RestoreCoinzixService
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var loginEnabled = false
    @Published private(set) var loginVisible = true
    @Published private(set) var loggingInVisible = false

    private let errorSubject = PassthroughSubject<String, Never>()
    private let successSubject = PassthroughSubject<Void, Never>()

    init(service: RestoreCoinzixService) {
        self.service = service

        service.$state
            .sink { [weak self] in self?.sync(state: $0) }
            .store(in: &cancellables)

        sync(state: service.state)
    }

    private func sync(state: RestoreCoinzixService.State) {
        switch state {
            case .notReady:
                loginEnabled = false
                loginVisible = true
                loggingInVisible = false
            case .idle(let error):
                loginEnabled = true
                loginVisible = true
                loggingInVisible = false

                if error != nil {
                    errorSubject.send("restore.coinzix.failed_to_login".localized)
                }
            case .loggingIn:
                loginVisible = false
                loggingInVisible = true
            case .loggedIn:
                successSubject.send()
        }
    }

}

extension RestoreCoinzixViewModel {

    var errorPublisher: AnyPublisher<String, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    var successPublisher: AnyPublisher<Void, Never> {
        successSubject.eraseToAnyPublisher()
    }

    func onChange(username: String) {
        service.username = username
    }

    func onChange(password: String) {
        service.password = password
    }

    func onTapLogin() {
        service.onCaptchaValidationStarted()
    }

    func onCaptchaValidated(captchaToken: String) {
        service.login(captchaToken: captchaToken)
    }

}

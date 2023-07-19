import Combine

class RestoreCoinzixViewModel {
    private let service: RestoreCoinzixService
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var loginEnabled = false
    @Published private(set) var loginVisible = true
    @Published private(set) var loggingInVisible = false

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
            case .ready:
                loginEnabled = true
                loginVisible = true
                loggingInVisible = false
         case .loggingIn:
                loginVisible = false
                loggingInVisible = true
        }
    }

}

extension RestoreCoinzixViewModel {

    var errorPublisher: AnyPublisher<String, Never> {
        service.errorPublisher.map { $0.smartDescription }.eraseToAnyPublisher()
    }

    var verifyPublisher: AnyPublisher<(CoinzixVerifyModule.Mode, [CoinzixCexProvider.TwoFactorType]), Never> {
        service.verifyPublisher
    }

    func onChange(username: String) {
        service.username = username
    }

    func onChange(password: String) {
        service.password = password
    }

    func onTapLogin() {
        service.login()
    }

}

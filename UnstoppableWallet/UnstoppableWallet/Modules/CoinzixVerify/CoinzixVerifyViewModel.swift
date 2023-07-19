import Combine
import HsExtensions

class CoinzixVerifyViewModel {
    private let service: CoinzixVerifyService
    private var cancellables = Set<AnyCancellable>()
    private var tasks = Set<AnyTask>()

    @Published private(set) var submitButtonState: AsyncActionButtonState = .disabled
    @Published private(set) var resendEnabled: Bool = false

    init(service: CoinzixVerifyService) {
        self.service = service

        service.$state
                .sink { [weak self] in self?.sync(state: $0) }
                .store(in: &cancellables)

        sync(state: service.state)
        setResendEnableTimer()
    }

    private func sync(state: CoinzixVerifyService.State) {
        switch state {
        case .notReady: submitButtonState = .disabled
        case .ready: submitButtonState = .enabled
        case .submitting: submitButtonState = .spinner
        }
    }

    private func setResendEnableTimer() {
        tasks = Set()
        resendEnabled = false

        Task { [weak self] in
            try? await Task.sleep(nanoseconds: CoinzixCexProvider.withdrawEmailPinResendTime)
            self?.resendEnabled = true
        }.store(in: &tasks)
    }

}

extension CoinzixVerifyViewModel {

    var successPublisher: AnyPublisher<Void, Never> {
        service.successPublisher
    }

    var errorPublisher: AnyPublisher<String, Never> {
        service.errorPublisher.map { $0.smartDescription }.eraseToAnyPublisher()
    }

    var twoFactorTypes: [CoinzixCexProvider.TwoFactorType] {
        service.twoFactorTypes
    }

    func onTapResend() {
        service.resendEmailPin()
        setResendEnableTimer()
    }

    func onTapSubmit() {
        service.submit()
    }

    func onChange(emailPin: String) {
        service.set(emailPin: emailPin)
    }

    func onChange(googlePin: String) {
        service.set(googlePin: googlePin)
    }

}

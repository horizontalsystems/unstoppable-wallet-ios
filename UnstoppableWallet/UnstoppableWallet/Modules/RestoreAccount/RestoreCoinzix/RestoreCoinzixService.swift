import Combine
import ObjectMapper
import HsToolKit
import HsExtensions

class RestoreCoinzixService {
    private let networkManager: NetworkManager
    private var tasks = Set<AnyTask>()

    var username: String = "" {
        didSet {
            syncState()
        }
    }

    var password: String = "" {
        didSet {
            syncState()
        }
    }

    @PostPublished private(set) var state: State = .notReady

    private let verifySubject = PassthroughSubject<(CoinzixVerifyModule.Mode, [CoinzixCexProvider.TwoFactorType]), Never>()
    private let errorSubject = PassthroughSubject<String, Never>()

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    private func syncState() {
        state = username.trimmingCharacters(in: .whitespaces).isEmpty || password.trimmingCharacters(in: .whitespaces).isEmpty ? .notReady : .ready
    }

    private func handle(loginResult: CoinzixCexProvider.LoginResult) {
        switch loginResult {
        case .success(let token, let secret, let twoFactorType):
            let type: CoinzixCexProvider.TwoFactorType

            switch twoFactorType {
            case .email: type = .email
            case .authenticator: type = .authenticator
            }

            verifySubject.send((.login(token: token, secret: secret), [type]))
        case .failed(let reason):
            switch reason {
            case .invalidCredentials(let attemptsLeft):
                errorSubject.send("Invalid login credentials. Attempts left: \(attemptsLeft).")
            case .tooManyAttempts(let unlockDate):
                errorSubject.send("Too many invalid login attempts were made. Login is locked until \(DateHelper.instance.formatFullTime(from: unlockDate)).")
            case .unknown(let message):
                errorSubject.send(message)
            }
        }
    }

}

extension RestoreCoinzixService {

    var verifyPublisher: AnyPublisher<(CoinzixVerifyModule.Mode, [CoinzixCexProvider.TwoFactorType]), Never> {
        verifySubject.eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<String, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    func login() {
        state = .loggingIn

        Task { [weak self, username, password, networkManager] in
            do {
                let loginResult = try await CoinzixCexProvider.login(username: username, password: password, networkManager: networkManager)
                self?.handle(loginResult: loginResult)
            } catch {
                self?.errorSubject.send(error.smartDescription)
            }

            self?.state = .ready
        }.store(in: &tasks)
    }

}

extension RestoreCoinzixService {

    enum State {
        case notReady
        case ready
        case loggingIn
    }

}

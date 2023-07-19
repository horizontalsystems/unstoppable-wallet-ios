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
    private let errorSubject = PassthroughSubject<Error, Never>()

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    private func syncState() {
        state = username.trimmingCharacters(in: .whitespaces).isEmpty || password.trimmingCharacters(in: .whitespaces).isEmpty ? .notReady : .ready
    }

    private func handle(loginData: CoinzixCexProvider.LoginData) {
        let type: CoinzixCexProvider.TwoFactorType

        switch loginData.twoFactorType {
        case .email: type = .email
        case .authenticator: type = .authenticator
        }

        verifySubject.send((.login(token: loginData.token, secret: loginData.secret), [type]))
    }

}

extension RestoreCoinzixService {

    var verifyPublisher: AnyPublisher<(CoinzixVerifyModule.Mode, [CoinzixCexProvider.TwoFactorType]), Never> {
        verifySubject.eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<Error, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    func login() {
        state = .loggingIn

        Task { [weak self, username, password, networkManager] in
            do {
                let loginData = try await CoinzixCexProvider.login(username: username, password: password, networkManager: networkManager)
                self?.handle(loginData: loginData)
            } catch {
                self?.errorSubject.send(error)
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

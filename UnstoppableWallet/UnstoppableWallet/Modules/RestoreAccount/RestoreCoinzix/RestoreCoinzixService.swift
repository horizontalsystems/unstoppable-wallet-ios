import Combine
import ObjectMapper
import HsToolKit
import HsExtensions

class RestoreCoinzixService {
    private let networkManager: NetworkManager
    private let accountFactory: AccountFactory
    private let accountManager: AccountManager
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

    init(networkManager: NetworkManager, accountFactory: AccountFactory, accountManager: AccountManager) {
        self.networkManager = networkManager
        self.accountFactory = accountFactory
        self.accountManager = accountManager
    }

    private func syncState() {
        state = username.trimmingCharacters(in: .whitespaces).isEmpty || password.trimmingCharacters(in: .whitespaces).isEmpty ? .notReady : .idle(error: nil)
    }

    private func createAccount(secretKey: String, token: String) {
        let type: AccountType = .cex(type: .coinzix(authToken: token, secret: secretKey))
        let name = accountFactory.nextAccountName(cex: .coinzix)
        let account = accountFactory.account(type: type, origin: .restored, backedUp: true, name: name)

        accountManager.save(account: account)

        state = .loggedIn
    }

}

extension RestoreCoinzixService {

    func onCaptchaValidationStarted() {
        state = .loggingIn
    }

    func login(captchaToken: String) {
        Task { [weak self, username, password, networkManager] in
            do {
                let (secretKey, token) = try await CoinzixCexProvider.login(username: username, password: password, captchaToken: captchaToken, networkManager: networkManager)
                self?.createAccount(secretKey: secretKey, token: token)
            } catch {
                self?.state = .idle(error: error)
            }
        }.store(in: &tasks)
    }

}

extension RestoreCoinzixService {

    enum State {
        case notReady
        case idle(error: Error?)
        case loggingIn
        case loggedIn
    }

}

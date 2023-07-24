import HsToolKit

class LoginCoinzixVerifyService: ICoinzixVerifyService {
    private let token: String
    private let secret: String
    private let networkManager: NetworkManager
    private let accountFactory: AccountFactory
    private let accountManager: AccountManager

    init(token: String, secret: String, networkManager: NetworkManager, accountFactory: AccountFactory, accountManager: AccountManager) {
        self.token = token
        self.secret = secret
        self.networkManager = networkManager
        self.accountFactory = accountFactory
        self.accountManager = accountManager
    }

    func verify(emailCode: String?, googleCode: String?) async throws {
        try await CoinzixCexProvider.validateCode(code: emailCode ?? googleCode ?? "", token: token, networkManager: networkManager)

        let type: AccountType = .cex(type: .coinzix(authToken: token, secret: secret))
        let name = accountFactory.nextAccountName(cex: .coinzix)
        let account = accountFactory.account(type: type, origin: .restored, backedUp: true, name: name)

        accountManager.save(account: account)
    }

    func resendPin() async throws {
        try await CoinzixCexProvider.resendPin(token: token, networkManager: networkManager)
    }

}

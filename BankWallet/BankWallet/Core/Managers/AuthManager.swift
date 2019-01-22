import RxSwift

class AuthManager {
    private let secureStorage: ISecureStorage
    private let coinStorage: ICoinStorage
    private let localStorage: ILocalStorage

    weak var walletManager: IWalletManager?
    weak var coinManager: ICoinManager?
    weak var pinManager: IPinManager?
    weak var transactionsManager: ITransactionManager?

    private(set) var authData: AuthData?

    init(secureStorage: ISecureStorage, coinStorage: ICoinStorage, localStorage: ILocalStorage, coinManager: ICoinManager) {
        self.secureStorage = secureStorage
        self.coinStorage = coinStorage
        self.localStorage = localStorage
        self.coinManager = coinManager

        authData = secureStorage.authData
    }

}

extension AuthManager: IAuthManager {

    var isLoggedIn: Bool {
        return authData != nil
    }

    func login(withWords words: [String]) throws {
        let authData = AuthData(words: words)
        try secureStorage.set(authData: authData)

        self.authData = authData

        coinManager?.enableDefaultCoins()
        walletManager?.initWallets()
    }

    func logout() throws {
        walletManager?.clearWallets()
        try pinManager?.clearPin()
        transactionsManager?.clear()
        localStorage.clear()
        coinStorage.cleanCoins()

        try secureStorage.set(authData: nil)
        authData = nil
    }

}

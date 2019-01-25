import RxSwift

class AuthManager {
    private let secureStorage: ISecureStorage
    private let localStorage: ILocalStorage
    private let pinManager: IPinManager
    private let coinManager: ICoinManager
    private let rateManager: IRateManager

    weak var walletManager: IWalletManager?

    private(set) var authData: AuthData?

    init(secureStorage: ISecureStorage, localStorage: ILocalStorage, pinManager: IPinManager, coinManager: ICoinManager, rateManager: IRateManager) {
        self.secureStorage = secureStorage
        self.localStorage = localStorage
        self.pinManager = pinManager
        self.coinManager = coinManager
        self.rateManager = rateManager

        authData = secureStorage.authData
    }

}

extension AuthManager: IAuthManager {

    var isLoggedIn: Bool {
        return authData != nil
    }

    func login(withWords words: [String], newWallet: Bool) throws {
        let authData = AuthData(words: words)
        try secureStorage.set(authData: authData)
        localStorage.isNewWallet = newWallet

        self.authData = authData

        coinManager.enableDefaultCoins()
        walletManager?.initWallets()
    }

    func logout() throws {
        walletManager?.clear()
        try pinManager.clear()
        localStorage.clear()
        coinManager.clear()
        rateManager.clear()

        try secureStorage.set(authData: nil)
        authData = nil
    }

}

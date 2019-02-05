import RxSwift

class AuthManager {
    private let secureStorage: ISecureStorage
    private let localStorage: ILocalStorage
    private let pinManager: IPinManager
    private let coinManager: ICoinManager
    private let rateManager: IRateManager
    private let ethereumKitManager: IEthereumKitManager

    weak var walletManager: IAdapterManager?

    private(set) var authData: AuthData?

    init(secureStorage: ISecureStorage, localStorage: ILocalStorage, pinManager: IPinManager, coinManager: ICoinManager, rateManager: IRateManager, ethereumKitManager: IEthereumKitManager) {
        self.secureStorage = secureStorage
        self.localStorage = localStorage
        self.pinManager = pinManager
        self.coinManager = coinManager
        self.rateManager = rateManager
        self.ethereumKitManager = ethereumKitManager

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
        walletManager?.initAdapters()
    }

    func logout() throws {
        walletManager?.clear()
        try ethereumKitManager.clear()
        try pinManager.clear()
        localStorage.clear()
        coinManager.clear()
        rateManager.clear()

        try secureStorage.set(authData: nil)
        authData = nil
    }

}

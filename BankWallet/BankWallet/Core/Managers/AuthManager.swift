import RxSwift

class AuthManager {
    private let secureStorage: ISecureStorage
    private let localStorage: ILocalStorage
    private let pinManager: IPinManager
    private let coinManager: ICoinManager
    private let rateManager: IRateManager
    private let ethereumKitManager: IEthereumKitManager

    weak var adapterManager: IAdapterManager?

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

    func login(withWords words: [String], syncMode: SyncMode) throws {
        try BitcoinAdapter.clear()
        try BitcoinCashAdapter.clear()
        try DashAdapter.clear()
        try EthereumAdapter.clear()
        try Erc20Adapter.clear()

        let authData = AuthData(words: words)
        try secureStorage.set(authData: authData)
        localStorage.syncMode = syncMode

        self.authData = authData

        coinManager.enableDefaultCoins()
        adapterManager?.initAdapters()
    }

    func logout() throws {
        try pinManager.clear()
        localStorage.clear()
        coinManager.clear()
        rateManager.clear()

        try secureStorage.set(authData: nil)
        authData = nil
    }

}

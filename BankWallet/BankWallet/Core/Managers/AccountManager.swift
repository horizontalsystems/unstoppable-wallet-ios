class AccountManager {
    private let secureStorage: ISecureStorage

    init(secureStorage: ISecureStorage) {
        self.secureStorage = secureStorage
    }

}

extension AccountManager: IAccountManager {

    var accounts: [Account] {
        // todo: implement this
        return []
    }

}

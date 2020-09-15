class RestoreEosService {
    private let appConfigProvider: IAppConfigProvider

    init(appConfigProvider: IAppConfigProvider) {
        self.appConfigProvider = appConfigProvider
    }

    var defaultAccount: String {
        appConfigProvider.defaultEosCredentials.0
    }

    var defaultPrivateKey: String {
        appConfigProvider.defaultEosCredentials.1
    }

    func accountType(account: String, privateKey: String) throws -> AccountType {
        let account = account.trimmingCharacters(in: .whitespaces).lowercased()
        let privateKey = privateKey.trimmingCharacters(in: .whitespaces)

        try EosAdapter.validate(account: account)
        try EosAdapter.validate(privateKey: privateKey)

        return .eos(account: account, activePrivateKey: privateKey)
    }

}

import CoinKit

class AddBep20TokenResolver: IAddEvmTokenResolver {
    private let appConfigProvider: IAppConfigProvider

    init(appConfigProvider: IAppConfigProvider) {
        self.appConfigProvider = appConfigProvider
    }

    var apiUrl: String {
        appConfigProvider.testMode ? "https://api-testnet.bscscan.com/api" : "https://api.bscscan.com/api"
    }

    var explorerKey: String {
        appConfigProvider.bscscanKey
    }

    func coinType(address: String) -> CoinType {
        .bep20(address: address)
    }

}

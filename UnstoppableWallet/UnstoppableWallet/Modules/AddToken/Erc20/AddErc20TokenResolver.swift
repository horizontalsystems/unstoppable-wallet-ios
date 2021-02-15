class AddErc20TokenResolver: IAddEvmTokenResolver {
    private let appConfigProvider: IAppConfigProvider

    init(appConfigProvider: IAppConfigProvider) {
        self.appConfigProvider = appConfigProvider
    }

    var apiUrl: String {
        appConfigProvider.testMode ? "https://api-ropsten.etherscan.io/api" : "https://api.etherscan.io/api"
    }

    var explorerKey: String {
        appConfigProvider.etherscanKey
    }

    func does(coin: Coin, matchReference reference: String) -> Bool {
        if case .erc20(let address) = coin.type, address.lowercased() == reference.lowercased() {
            return true
        }

        return false
    }

    func coinType(address: String) -> CoinType {
        .erc20(address: address)
    }

}

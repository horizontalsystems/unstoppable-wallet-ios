class AddErc20TokenResolver: IAddEvmTokenResolver {

    func apiUrl(testMode: Bool) -> String {
        testMode ? "https://api-ropsten.etherscan.io/api" : "https://api.etherscan.io/api"
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

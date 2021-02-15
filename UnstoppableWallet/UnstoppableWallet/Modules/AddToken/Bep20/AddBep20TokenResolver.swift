class AddBep20TokenResolver: IAddEvmTokenResolver {

    func apiUrl(testMode: Bool) -> String {
        testMode ? "https://api-testnet.bscscan.com/api" : "https://api.bscscan.com/api"
    }

    func does(coin: Coin, matchReference reference: String) -> Bool {
        if case .bep20(let address) = coin.type, address.lowercased() == reference.lowercased() {
            return true
        }

        return false
    }

    func coinType(address: String) -> CoinType {
        .bep20(address: address)
    }

}

import HsToolKit

class CexProviderFactory {
    private let networkManager: NetworkManager

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    func provider(type: CexType) -> ICexProvider {
        switch type {
        case .binance(let apiKey, let secret):
            return BinanceCexProvider(
                    networkManager: networkManager,
                    apiKey: apiKey,
                    secret: secret
            )
        case .coinzix(let authToken, let secret):
            return CoinzixCexProvider(
                    networkManager: networkManager,
                    authToken: authToken,
                    secret: secret
            )
        }
    }

}

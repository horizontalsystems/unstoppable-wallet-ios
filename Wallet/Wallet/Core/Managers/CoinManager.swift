import Foundation

class CoinManager {

    private let supportedCoins = [Bitcoin(), BitcoinTestNet(), BitcoinRegTest(), BitcoinCash()]

    func getCoin(byCode code: String) -> Coin? {
        return supportedCoins.first(where: { $0.code == code })
    }

}

import Foundation

class CoinManager {

    private let supportedCoins = [Bitcoin(), Bitcoin(networkSuffix: "T"), Bitcoin(networkSuffix: "R"), BitcoinCash()]

    func getCoin(byCode code: String) -> Coin? {
        return supportedCoins.first(where: { $0.code == code })
    }

}

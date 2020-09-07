import Foundation

class RateCoinMapper {
    private let disabledCoins = ["EOSDT", "PGL", "PPT", "SAI", "WBTC", "WETH", "SWAP"]
    private let convertedCoins = [
        "HOT": "HOLO",
    ]
}

extension RateCoinMapper: IRateCoinMapper {

    func convert(coinCode: String) -> String? {
        guard !disabledCoins.contains(coinCode) else {
            return nil
        }

        return convertedCoins[coinCode] ?? coinCode
    }

    func unconvert(coinCode: String) -> [String] {
        var coinCodes = [coinCode]

        for (from, to) in convertedCoins {
            if to == coinCode {
                coinCodes.append(from)
            }
        }

        return coinCodes
    }

}

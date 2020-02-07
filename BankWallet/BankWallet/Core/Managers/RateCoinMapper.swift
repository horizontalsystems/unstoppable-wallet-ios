import Foundation

enum RateDirectionMap {
    case convert
    case unconvert
}

class RateCoinMapper {
    private let nonExistCoin = "AI-DAI"
    private(set) var blockedCoins = Set<String>()
    private(set) var convertCoinMap = [String: String]()
    private(set) var unconvertCoinMap = [String: String]()
}

extension RateCoinMapper: IRateCoinMapper {

    func addCoin(direction: RateDirectionMap, from: String, to: String?) {
        if to == nil {
            blockedCoins.insert(from)
        }
        switch direction {
        case .convert: convertCoinMap[from] = to ?? nonExistCoin
        case .unconvert: unconvertCoinMap[from] = to ?? nonExistCoin
        }
    }

}

extension RateCoinMapper: IBlockedChartCoins {}
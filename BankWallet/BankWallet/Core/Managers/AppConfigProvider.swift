import Foundation

class AppConfigProvider: IAppConfigProvider {

    var enabledCoins: [Coin] {
        if let coins = Bundle.main.object(forInfoDictionaryKey: "Enabled Coins") as? String {
            return coins.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        }
        return []
    }

}

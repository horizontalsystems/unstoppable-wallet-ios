import Foundation

class CoinValueHelper {

    static func formattedAmount(for value: CoinValue) -> String {
        return "\(abs(value.value)) \(value.coinCode)"
    }

}

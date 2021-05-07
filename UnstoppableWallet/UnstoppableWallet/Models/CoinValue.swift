import Foundation
import CoinKit

struct CoinValue {
    let coin: Coin
    let value: Decimal

    var formattedString: String {
        ValueFormatter.instance.format(coinValue: self) ?? ""
    }

    var formattedRawString: String {
        ValueFormatter.instance.format(coinValue: self, showCode: false) ?? ""
    }

}

extension CoinValue: Equatable {

    public static func ==(lhs: CoinValue, rhs: CoinValue) -> Bool {
        lhs.coin == rhs.coin && lhs.value == rhs.value
    }

}

import Foundation
import CoinKit
import BigInt

fileprivate let max256ByteNumber = BigUInt(Data(hex: "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"))

struct CoinValue {
    let coin: Coin
    let value: Decimal

    var isMaxValue: Bool {
        let maxInDecimal = Decimal(sign: .plus, exponent: -coin.decimal, significand: Decimal(string: max256ByteNumber.description)!)

        return maxInDecimal == value
    }

    var abs: CoinValue {
        CoinValue(coin: coin, value: value.magnitude)
    }

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

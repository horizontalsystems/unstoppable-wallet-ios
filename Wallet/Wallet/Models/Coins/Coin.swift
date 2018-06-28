import Foundation

class Coin {

    var name: String { fatalError("Abstract var") }
    var code: String { fatalError("Abstract var") }

}

extension Coin: Hashable {

    var hashValue: Int {
        return code.hashValue
    }

    public static func == (lhs: Coin, rhs: Coin) -> Bool {
        return lhs.code == rhs.code
    }

}

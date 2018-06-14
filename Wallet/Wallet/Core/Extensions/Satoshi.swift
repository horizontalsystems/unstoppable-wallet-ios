import Foundation

typealias Satoshi = Int64

extension Satoshi {

    var toDouble: Double {
        return Double(self) / 100000000
    }

}

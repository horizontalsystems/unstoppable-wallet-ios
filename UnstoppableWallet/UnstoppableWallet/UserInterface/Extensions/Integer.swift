import Foundation

extension Int {
    var digits: Int {
        Int(floor(log10(Float(self))) + 1)
    }

    func significant(depth: Int) -> Int {
        let digitCount: Int = Swift.max(0, digits - depth)
        return (pow(Decimal(10), digitCount) as NSDecimalNumber).intValue
    }
}

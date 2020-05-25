import Foundation
import BigInt

class ERC20InputParser {

    static func parse(input: String) -> InputData? {
        var inputData = InputData()

        let input = input.replacingOccurrences(of: "0x", with: "")
        if input.contains("a9059cbb") {
            let startToIndex = input.index(input.startIndex, offsetBy: 8 + 24)
            inputData.to = address(fromString: input, startIndex: startToIndex)

            let endToIndex = input.index(startToIndex, offsetBy: 40)
            inputData.value = value(fromString: input, startIndex: endToIndex)
        } else if input.contains("23b872dd") {
            let startToIndex = input.index(input.startIndex, offsetBy: 8 + 64 + 24)
            inputData.to = address(fromString: input, startIndex: startToIndex)

            let endToIndex = input.index(startToIndex, offsetBy: 40)
            inputData.value = value(fromString: input, startIndex: endToIndex)
        }
        return inputData
    }

    private static func value(fromString string: String, startIndex: String.Index) -> Decimal? {
        let endIndex = string.index(startIndex, offsetBy: 64)
        let amountHexString = String(string[startIndex..<endIndex])
        if let weiAmount = BigInt(amountHexString, radix: 16), let weiAmountDecimal = Decimal(string: "\(weiAmount)") {
            return weiAmountDecimal
        }
        return nil
    }

    private static func address(fromString string: String, startIndex: String.Index) -> String {
        let endIndex = string.index(startIndex, offsetBy: 40)
        return "0x" + String(string[startIndex..<endIndex])
    }

}

struct InputData {
    var from: String?
    var to: String?
    var value: Decimal?
}

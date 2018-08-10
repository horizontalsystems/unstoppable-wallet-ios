import Foundation

class UnspentOutputSelector {

    enum SelectorError: Error {
        case emptyOutputs
        case notEnough
    }

    func select(value: Int, outputs: [TransactionOutput]) throws -> [TransactionOutput] {
        guard !outputs.isEmpty else {
            throw SelectorError.emptyOutputs
        }
        var selected = [TransactionOutput]()
        if let output = outputs.first(where: { $0.value == value }) {
            selected.append(output)
            return selected
        }
        let sortedOutputs = outputs.sorted(by: { lhs, rhs in lhs.value < rhs.value })

        var total = 0
        for output in sortedOutputs {
            if total >= value {
                break
            }
            selected.append(output)
            total += output.value
        }
        if total < value {
            throw SelectorError.notEnough
        }

        return selected
    }

    private func calculateTxSize(txSize: Int, outputs: [TransactionOutput]) -> Int {
        var total = txSize
        total += Int(VarInt(outputs.count).length)
        outputs.forEach {
            total += $0.scriptType.size
        }
        return total
    }

}

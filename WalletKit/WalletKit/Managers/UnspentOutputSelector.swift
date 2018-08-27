import Foundation

struct SelectedUnspentOutputInfo {
    let outputs: [TransactionOutput]
    let totalValue: Int                 // summary value on selected unspent outputs
    let fee: Int                        // fee for transaction with 1 output and all selected inputs(unspent outputs)
}

class UnspentOutputSelector {
    enum SelectorError: Error {
        case emptyOutputs
        case notEnough
    }

    let calculator: TransactionSizeCalculator

    init(calculator: TransactionSizeCalculator) {
        self.calculator = calculator
    }

    func select(value: Int, feeRate: Int, senderPay: Bool, outputs: [TransactionOutput]) throws -> SelectedUnspentOutputInfo {
        guard !outputs.isEmpty else {
            throw SelectorError.emptyOutputs
        }

        var selected = [TransactionOutput]()
        var calculatedFee = (calculator.transactionSize() + calculator.outputSize(type: .p2pkh)) * feeRate // fee

        let dust = calculator.inputSize(type: .p2pkh) * feeRate // fee needed for make changeOutput

        // try to find 1 unspent output with exactly matching value
        if let output = outputs.first(where: {
            let totalFee = senderPay ? (calculatedFee + calculator.inputSize(type: $0.scriptType) * feeRate) : 0
            return (value + totalFee <= $0.value) && (value + totalFee + dust > $0.value)               //value + input fee + dust
        }) {
            selected.append(output)
            calculatedFee += calculator.inputSize(type: output.scriptType) * feeRate
            return SelectedUnspentOutputInfo(outputs: selected, totalValue: output.value, fee: calculatedFee)
        }

        let sortedOutputs = outputs.sorted(by: { lhs, rhs in lhs.value < rhs.value })

        // select outputs with least value until we get needed value
        var totalValue = 0
        for output in sortedOutputs {
            if totalValue >= value + (senderPay ? calculatedFee : 0) {
                break
            }
            selected.append(output)
            calculatedFee += calculator.inputSize(type: output.scriptType) * feeRate
            totalValue += output.value
        }

        // if all outputs are selected and total value less than needed throw error
        if totalValue < value + (senderPay ? calculatedFee : 0) {
            throw UnspentOutputSelector.SelectorError.notEnough
        }

        return SelectedUnspentOutputInfo(outputs: selected, totalValue: totalValue, fee: calculatedFee)
    }

}

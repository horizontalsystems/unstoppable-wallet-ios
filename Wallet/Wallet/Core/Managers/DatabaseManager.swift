import Foundation
import RxSwift

class DatabaseManager: IDatabaseManager {

    func getUnspentOutputs() -> [UnspentOutput] {
        return [
            UnspentOutput(value: 32500000, index: 0, confirmations: 0, transactionHash: "", script: ""),
            UnspentOutput(value: 16250000, index: 0, confirmations: 0, transactionHash: "", script: "")
        ]
    }

    func insert(unspentOutputs: [UnspentOutput]) {
    }

    func truncateUnspentOutputs() {
    }

    func getExchangeRates() -> [String: Double] {
        return [Bitcoin().code: 7200]
    }

    func insert(exchangeRates: [String: Double]) {
    }

    func truncateExchangeRates() {
    }

}

import Foundation

protocol IBitcoinTxResponse {
    var btcRate: Double { get }

    var txId: String? { get }
    var blockTime: Int? { get }
    var blockHeight: Int? { get }
    var confirmations: Int? { get }

    var size: Int? { get }
    var fee: Double? { get }
    var feePerByte: Double? { get }

    var inputs: [(value: Double, address: String?)] { get }
    var outputs: [(value: Double, address: String?)] { get }
}

extension IBitcoinTxResponse {
    var btcRate: Double {
        return 100_000_000
    }
}
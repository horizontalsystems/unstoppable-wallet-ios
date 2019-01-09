import Foundation

protocol IEthereumTxResponse {
    var ethRate: Double { get }
    var gweiRate: Double { get }

    var txId: String? { get }
    var blockTime: Int? { get }
    var blockHeight: Int? { get }
    var confirmations: Int? { get }

    var size: Int? { get }
    var gasPrice: Double? { get }
    var gasUsed: Double? { get }
    var gasLimit: Double? { get }
    var value: Double? { get }

    var nonce: Int? { get }
    var from: String? { get }
    var to: String? { get }
}

extension IEthereumTxResponse {
    var ethRate: Double {
        return 1_000_000_000_000_000_000
    }
    var gweiRate: Double {
        return 1_000_000_000
    }
}
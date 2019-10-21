import Foundation

protocol IEosResponse {
    var txId: String? { get }
    var status: String? { get }
    var cpuUsage: Int? { get }
    var netUsage: Int? { get }
    var blockNumber: Int? { get }
    var blockTime: Date? { get }

    var actions: [EosAction] { get }
}

protocol IBitcoinResponse {
    var btcRate: Decimal { get }

    var txId: String? { get }
    var blockTime: Int? { get }
    var blockHeight: Int? { get }
    var confirmations: Int? { get }

    var size: Int? { get }
    var fee: Decimal? { get }
    var feePerByte: Decimal? { get }

    var inputs: [(value: Decimal, address: String?)] { get }
    var outputs: [(value: Decimal, address: String?)] { get }
}

extension IBitcoinResponse {
    var btcRate: Decimal {
        return 100_000_000
    }
}

protocol IEthereumResponse {
    var ethRate: Decimal { get }
    var gweiRate: Decimal { get }

    var txId: String? { get }
    var blockTime: Int? { get }
    var blockHeight: Int? { get }
    var confirmations: Int? { get }

    var size: Int? { get }
    var gasPrice: Decimal? { get }
    var gasUsed: Decimal? { get }
    var gasLimit: Decimal? { get }
    var fee: Decimal? { get }
    var value: Decimal? { get }

    var nonce: Int? { get }
    var from: String? { get }
    var to: String? { get }
    var contractAddress: String? { get }
}

extension IEthereumResponse {
    var ethRate: Decimal {
        return 1_000_000_000_000_000_000
    }
    var gweiRate: Decimal {
        return 1_000_000_000
    }
}

protocol IBinanceResponse {
    var txId: String? { get }
    var blockHeight: Int? { get }

    var fee: Decimal? { get }
    var value: Decimal? { get }

    var from: String? { get }
    var to: String? { get }

    var memo: String? { get }
}

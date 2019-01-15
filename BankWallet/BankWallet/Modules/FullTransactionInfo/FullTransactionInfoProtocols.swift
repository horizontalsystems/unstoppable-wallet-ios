protocol IBitcoinResponse {
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

extension IBitcoinResponse {
    var btcRate: Double {
        return 100_000_000
    }
}

protocol IEthereumResponse {
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
    var fee: Double? { get }
    var value: Double? { get }

    var nonce: Int? { get }
    var from: String? { get }
    var to: String? { get }
}

extension IEthereumResponse {
    var ethRate: Double {
        return 1_000_000_000_000_000_000
    }
    var gweiRate: Double {
        return 1_000_000_000
    }
}

protocol IBitcoinForksProvider: IProvider {
    func convert(json: [String: Any]) -> IBitcoinResponse?
}

protocol IEthereumForksProvider: IProvider {
    func convert(json: [String: Any]) -> IEthereumResponse?
}

import Foundation
import MarketKit

struct AddressUri: Equatable {
    let scheme: String
    var address: String = ""

    var parameters: [Field: String] = [:]
    var unhandledParameters: [String: String] = [:]

    init(scheme: String) {
        self.scheme = scheme
    }

    func value<T>(field: Field) -> T? {
        var value: Any?
        switch T.self {
        case is String.Type: value = parameters[field]
        case is Decimal.Type: value = parameters[field].flatMap { Decimal(string: $0) }
        case is Int.Type: value = parameters[field].flatMap { Int($0) }
        default: return nil
        }

        return value.map { $0 as! T }
    }

    var amount: Amount? {
        value(field: .value).map { .points($0) } ??
            (value(field: .amount) ?? value(field: .txAmount)).map { .decimals($0) }
    }

    var memo: String? {
        value(field: .txDescription)
    }

    static func == (lhs: AddressUri, rhs: AddressUri) -> Bool {
        lhs.address == rhs.address &&
            lhs.parameters == rhs.parameters &&
            lhs.unhandledParameters == rhs.unhandledParameters
    }
}

extension AddressUri {
    static func toUri(field: AddressUri.Field, amount: Decimal, token: Token) -> Decimal {
        switch field {
        case .value: return amount.fromReadable(decimals: token.decimals)
        case .txAmount, .amount: return amount
        default: return 0
        }
    }

    enum Field: String, CaseIterable {
        case amount
        case value
        case txAmount = "tx_amount"
        case txDescription = "tx_description"
        case label
        case message
        case blockchainUid = "blockchain_uid"
        case tokenUid = "token_uid"

        static func amountField(blockchainType: BlockchainType) -> Self {
            if blockchainType.isEvm {
                return .value
            }
            if blockchainType == .monero {
                return .txAmount
            }
            return .amount
        }
    }

    enum Amount {
        case points(Decimal) // lamports, satoshi, wei
        case decimals(Decimal) // human readable

        var description: String {
            switch self {
            case let .points(decimal):
                return "P:\(decimal)"
            case let .decimals(decimal):
                return "D:\(decimal)"
            }
        }

        func humanReadable(decimals: Int) -> Decimal {
            switch self {
            case let .points(decimal):
                return decimal.toReadable(decimals: decimals)
            case let .decimals(decimal):
                return decimal
            }
        }
    }
}

extension AddressUri {
    var allowedBlockchainTypes: [BlockchainType]? {
        if let concreteUid: String = value(field: .blockchainUid) {
            return [BlockchainType(uid: concreteUid)]
        }

        if let type = BlockchainType.supported.first(where: { $0.uriScheme == scheme }) {
            // For any evm types uses ethereum:_ scheme
            if EvmBlockchainManager.blockchainTypes.contains(type) {
                return EvmBlockchainManager.blockchainTypes
            }

            return [type]
        }

        return nil
    }
}

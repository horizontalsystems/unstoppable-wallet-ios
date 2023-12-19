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

    var amount: Decimal? {
        value(field: .amount) ?? value(field: .value)
    }

    static func == (lhs: AddressUri, rhs: AddressUri) -> Bool {
        lhs.address == rhs.address &&
            lhs.parameters == rhs.parameters &&
            lhs.unhandledParameters == rhs.unhandledParameters
    }
}

extension AddressUri {
    enum Field: String, CaseIterable {
        case amount
        case value
        case label
        case message
        case blockchainUid = "blockchain_uid"
        case tokenUid = "token_uid"

        static func amountField(blockchainType: BlockchainType) -> Self {
            if EvmBlockchainManager.blockchainTypes.contains(blockchainType) {
                return .value
            }
            return .amount
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

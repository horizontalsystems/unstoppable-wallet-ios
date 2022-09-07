import GRDB
import MarketKit

enum NftUid: Hashable {
    case evm(blockchainType: BlockchainType, contractAddress: String, tokenId: String)
    case solana(contractAddress: String, tokenId: String)

    init?(uid: String) {
        let parts = uid.components(separatedBy: "|")

        guard parts.count > 0 else {
            return nil
        }

        switch parts[0] {
        case "evm":
            guard parts.count == 4 else {
                return nil
            }

            self = .evm(blockchainType: BlockchainType(uid: parts[1]), contractAddress: parts[2], tokenId: parts[3])
        case "solana":
            guard parts.count == 3 else {
                return nil
            }

            self = .solana(contractAddress: parts[1], tokenId: parts[2])
        default:
            return nil
        }
    }

    var uid: String {
        switch self {
        case let .evm(blockchainType, contractAddress, tokenId): return "evm|\(blockchainType.uid)|\(contractAddress)|\(tokenId)"
        case let .solana(contractAddress, tokenId): return "solana|\(contractAddress)|\(tokenId)"
        }
    }

    var tokenId: String {
        switch self {
        case let .evm(_, _, tokenId): return tokenId
        case let .solana(_, tokenId): return tokenId
        }
    }

    var contractAddress: String {
        switch self {
        case let .evm(_, contractAddress, _): return contractAddress
        case let .solana(contractAddress, _): return contractAddress
        }
    }

    var blockchainType: BlockchainType {
        switch self {
        case let .evm(blockchainType, _, _): return blockchainType
        case .solana: return .solana
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(uid)
    }

    static func ==(lhs: NftUid, rhs: NftUid) -> Bool {
        switch (lhs, rhs) {
        case let (.evm(lhsBlockchainType, lhsContractAddress, lhsTokenId), .evm(rhsBlockchainType, rhsContractAddress, rhsTokenId)): return lhsBlockchainType == rhsBlockchainType && lhsContractAddress == rhsContractAddress && lhsTokenId == rhsTokenId
        case let (.solana(lhsContractAddress, lhsTokenId), .solana(rhsContractAddress, rhsTokenId)): return lhsContractAddress == rhsContractAddress && lhsTokenId == rhsTokenId
        default: return false
        }
    }

}

extension NftUid: DatabaseValueConvertible {

    var databaseValue: DatabaseValue {
        uid.databaseValue
    }

    static func fromDatabaseValue(_ dbValue: DatabaseValue) -> NftUid? {
        guard let uid = String.fromDatabaseValue(dbValue) else {
            return nil
        }

        return NftUid(uid: uid)
    }

}

import BigInt
import Foundation
import HsCryptoKit
import TronKit

// EIP-712 / TIP-712 PermitTransfer message hashing for the GasFree.io provider.
//
// Layout follows the canonical EIP-712 spec (Tron's TIP-712 is a verbatim port — same
// keccak256 + ABI encoding):
//
//   domainSeparator = keccak256(domainTypeHash || encoded(domain))
//   structHash      = keccak256(messageTypeHash || encoded(message))
//   finalHash       = keccak256(0x1901 || domainSeparator || structHash)
//
// All struct fields are static types (address / uint256), so each `encoded(...)` collapses
// to a left-padded 32-byte slot. Strings inside the domain (`name`, `version`) are
// pre-hashed per the spec.
//
// Canonical hash vector verified in PermitTransferHashTests against the upstream
// `gasfreeio/gasfree-sdk-swift` Tests.swift fixture.
enum PermitTransfer {
    static func hash(domain: GasFreeDomain, message: Message) -> Data {
        let domainSeparator = encodeDomainSeparator(domain)
        let structHash = encodeStructHash(message)

        var preimage = Data()
        preimage.append(0x19)
        preimage.append(0x01)
        preimage.append(domainSeparator)
        preimage.append(structHash)

        return Crypto.sha3(preimage)
    }

    // MARK: - Encoding

    private static let domainTypeString =
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    private static let messageTypeString =
        "PermitTransfer(address token,address serviceProvider,address user,address receiver,uint256 value,uint256 maxFee,uint256 deadline,uint256 version,uint256 nonce)"

    private static var domainTypeHash: Data { Crypto.sha3(Data(domainTypeString.utf8)) }
    private static var messageTypeHash: Data { Crypto.sha3(Data(messageTypeString.utf8)) }

    private static func encodeDomainSeparator(_ domain: GasFreeDomain) -> Data {
        var encoded = Data()
        encoded.append(domainTypeHash)
        encoded.append(Crypto.sha3(Data(domain.name.utf8)))
        encoded.append(Crypto.sha3(Data(domain.version.utf8)))
        encoded.append(AbiEncoder.pad32(domain.chainId.serialize()))
        encoded.append(AbiEncoder.pad32(domain.verifyingContract.nonPrefixed))
        return Crypto.sha3(encoded)
    }

    private static func encodeStructHash(_ m: Message) -> Data {
        var encoded = Data()
        encoded.append(messageTypeHash)
        encoded.append(AbiEncoder.pad32(m.token.nonPrefixed))
        encoded.append(AbiEncoder.pad32(m.serviceProvider.nonPrefixed))
        encoded.append(AbiEncoder.pad32(m.user.nonPrefixed))
        encoded.append(AbiEncoder.pad32(m.receiver.nonPrefixed))
        encoded.append(AbiEncoder.pad32(m.value.serialize()))
        encoded.append(AbiEncoder.pad32(m.maxFee.serialize()))
        encoded.append(AbiEncoder.pad32(BigUInt(m.deadline).serialize()))
        encoded.append(AbiEncoder.pad32(BigUInt(m.version).serialize()))
        encoded.append(AbiEncoder.pad32(BigUInt(m.nonce).serialize()))
        return Crypto.sha3(encoded)
    }
}

extension PermitTransfer {
    struct Message: Equatable {
        let token: TronKit.Address
        let serviceProvider: TronKit.Address
        let user: TronKit.Address
        let receiver: TronKit.Address
        let value: BigUInt
        let maxFee: BigUInt
        let deadline: Int64
        let version: Int64
        let nonce: Int64
    }
}

struct GasFreeDomain: Equatable {
    let name: String
    let version: String
    let chainId: BigUInt
    let verifyingContract: TronKit.Address

    static func mainnet() -> GasFreeDomain {
        GasFreeDomain(
            name: "GasFreeController",
            version: "V1.0.0",
            chainId: GasFreeChainAddresses.mainnetChainId,
            verifyingContract: GasFreeChainAddresses.mainnetFactory
        )
    }
}

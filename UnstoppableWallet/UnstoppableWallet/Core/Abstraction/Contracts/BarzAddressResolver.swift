import BigInt
import EvmKit
import Foundation
import HsCryptoKit
import HsToolKit
import MarketKit

enum BarzAddressResolver {
    typealias Call = (_ contractAddress: EvmKit.Address, _ data: Data) async throws -> Data

    enum ResolveError: Error {
        case unsupportedChain
    }

    static func resolveLocally(
        publicKeyX: Data,
        publicKeyY: Data,
        blockchainType: BlockchainType,
        salt: BigUInt = 0
    ) throws -> EvmKit.Address {
        guard ChainAddresses.aa(for: blockchainType) != nil else {
            throw ResolveError.unsupportedChain
        }

        let owner = try BarzFactory.encodeSecp256r1PublicKey(x: publicKeyX, y: publicKeyY)
        let constructorArgs = AbiEncoder.encode(
            arguments: [
                .address(ChainAddresses.barzAccountFacet),
                .address(ChainAddresses.secp256r1VerificationFacet),
                .address(ChainAddresses.entryPointV06),
                .address(ChainAddresses.barzFacetRegistry),
                .address(ChainAddresses.barzDefaultFallback),
                .bytes(owner),
            ]
        )
        let initCodeHash = Crypto.sha3(ChainAddresses.barzCreationCode + constructorArgs)
        let create2Input = Data([0xFF]) + ChainAddresses.barzFactory.raw + pad32(value: salt) + initCodeHash

        return EvmKit.Address(raw: Crypto.sha3(create2Input).suffix(20))
    }

    static func resolveViaFactory(
        publicKeyX: Data,
        publicKeyY: Data,
        blockchainType: BlockchainType,
        salt: BigUInt = 0,
        call: Call
    ) async throws -> EvmKit.Address {
        guard let aa = ChainAddresses.aa(for: blockchainType) else {
            throw ResolveError.unsupportedChain
        }

        let owner = try BarzFactory.encodeSecp256r1PublicKey(x: publicKeyX, y: publicKeyY)
        let data = BarzFactory.encodeGetAddress(
            verificationFacet: aa.secp256r1VerificationFacet,
            owner: owner,
            salt: salt
        )
        let response = try await call(aa.barzFactory, data)

        return try BarzFactory.decodeGetAddress(response)
    }

    static func resolveViaFactory(
        publicKeyX: Data,
        publicKeyY: Data,
        blockchainType: BlockchainType,
        networkManager: NetworkManager,
        rpcSource: RpcSource,
        salt: BigUInt = 0
    ) async throws -> EvmKit.Address {
        try await resolveViaFactory(
            publicKeyX: publicKeyX,
            publicKeyY: publicKeyY,
            blockchainType: blockchainType,
            salt: salt,
            call: { contractAddress, data in
                try await EvmKit.Kit.call(
                    networkManager: networkManager,
                    rpcSource: rpcSource,
                    contractAddress: contractAddress,
                    data: data,
                    defaultBlockParameter: .latest
                )
            }
        )
    }

    private static func pad32(value: BigUInt) -> Data {
        let bytes = value.serialize()
        return Data(repeating: 0, count: max(0, 32 - bytes.count)) + bytes
    }
}

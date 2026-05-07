import Foundation
import HsCryptoKit
import TronKit

// Local CREATE2-style derivation of a user's GasFree address. Algorithm 1:1 from
// gasfreeio/gasfree-sdk-swift `GasFreeGenerator.generateGasFreeAddress`.
//
// Layout:
//   initData       = abi.encodeCall("initialize(address)", user)
//   ctorArgs       = abi.encode(beacon, initData)             // BeaconProxy(address,bytes)
//   bytecodeHash   = keccak256(creationCode || ctorArgs)
//   salt           = pad32(user_20bytes)
//   gasFreeAddress = base58check( 0x41 || keccak256(0x41 || factory_20bytes || salt || bytecodeHash)[12..] )
enum GasFreeAddressResolver {
    static func resolveLocally(userAddress: TronKit.Address) throws -> TronKit.Address {
        let user20 = userAddress.nonPrefixed
        let beacon20 = GasFreeChainAddresses.mainnetBeacon.nonPrefixed
        let factory20 = GasFreeChainAddresses.mainnetFactory.nonPrefixed

        let initData = AbiEncoder.encodeFunction(
            signature: "initialize(address)",
            arguments: [.address(user20)]
        )
        let ctorArgs = AbiEncoder.encode(arguments: [
            .address(beacon20),
            .bytes(initData),
        ])
        let bytecodeHash = Crypto.sha3(GasFreeChainAddresses.mainnetCreationCode + ctorArgs)

        let salt = AbiEncoder.pad32(user20)

        var mergeData = Data()
        mergeData.append(0x41)
        mergeData.append(factory20)
        mergeData.append(salt)
        mergeData.append(bytecodeHash)

        let derived20 = Crypto.sha3(mergeData).suffix(20)
        // `Address(raw:)` auto-prefixes 0x41 and computes the base58check checksum.
        return try TronKit.Address(raw: Data(derived20))
    }
}

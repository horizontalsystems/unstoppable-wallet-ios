import BigInt
import EvmKit
import Foundation

enum AccountFacet {
    static func encodeExecute(
        target: EvmKit.Address,
        value: BigUInt,
        data: Data
    ) -> Data {
        AbiEncoder.encodeFunction(
            signature: "execute(address,uint256,bytes)",
            arguments: [
                .address(target),
                .uint(value),
                .bytes(data),
            ]
        )
    }

    static func encodeExecuteBatch(calls: [UserOperationCallData]) -> Data {
        AbiEncoder.encodeFunction(
            signature: "executeBatch(address[],uint256[],bytes[])",
            arguments: [
                .array(calls.map { .address($0.target) }),
                .array(calls.map { .uint($0.value) }),
                .array(calls.map { .bytes($0.data) }),
            ]
        )
    }
}

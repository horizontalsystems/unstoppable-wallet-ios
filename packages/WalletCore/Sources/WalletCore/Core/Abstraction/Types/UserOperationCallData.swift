import BigInt
import EvmKit
import Foundation

public struct UserOperationCallData: Equatable, Hashable {
    public let target: EvmKit.Address
    public let value: BigUInt
    public let data: Data

    public init(target: EvmKit.Address, value: BigUInt = 0, data: Data = Data()) {
        self.target = target
        self.value = value
        self.data = data
    }
}

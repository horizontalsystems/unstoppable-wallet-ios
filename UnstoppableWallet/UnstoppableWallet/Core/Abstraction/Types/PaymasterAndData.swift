import EvmKit
import Foundation

public struct PaymasterAndData: Equatable, Hashable {
    public let paymaster: EvmKit.Address
    public let data: Data

    public init(paymaster: EvmKit.Address, data: Data = Data()) {
        self.paymaster = paymaster
        self.data = data
    }

    public func encoded() -> Data {
        paymaster.raw + data
    }

    public static func empty() -> Data {
        Data()
    }
}

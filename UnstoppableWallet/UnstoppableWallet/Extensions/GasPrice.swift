import EvmKit

extension GasPrice: Equatable {
    public static func == (lhs: GasPrice, rhs: GasPrice) -> Bool {
        switch (lhs, rhs) {
        case let (.legacy(lhsGasPrice), .legacy(rhsGasPrice)):
            return lhsGasPrice == rhsGasPrice
        case (let .eip1559(lhsMaxFee, lhsMaxTips), let .eip1559(rhsMaxFee, rhsMaxTips)):
            return lhsMaxFee == rhsMaxFee && lhsMaxTips == rhsMaxTips
        default:
            return false
        }
    }
}

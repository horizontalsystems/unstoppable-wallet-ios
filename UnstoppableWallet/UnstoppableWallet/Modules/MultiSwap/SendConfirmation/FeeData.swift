enum FeeData {
    case evm(evmFeeData: EvmFeeData)
    case bitcoin(bytes: Int)

    var gasLimit: Int? {
        switch self {
        case let .evm(evmFeeData): return evmFeeData.gasLimit
        default: return nil
        }
    }
}

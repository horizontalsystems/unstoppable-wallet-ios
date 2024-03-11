enum FeeData {
    case evm(gasLimit: Int)
    case bitcoin(bytes: Int)

    var gasLimit: Int? {
        switch self {
        case let .evm(gasLimit): return gasLimit
        default: return nil
        }
    }
}

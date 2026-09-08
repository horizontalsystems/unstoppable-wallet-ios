struct WCSwapInfo: Equatable {
    enum Provider {
        case oneInch
        case uniswap
    }

    let provider: Provider
    let tokenInIsNative: Bool
}

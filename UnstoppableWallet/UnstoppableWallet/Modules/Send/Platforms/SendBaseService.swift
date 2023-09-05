struct SendBaseService {}

extension SendBaseService {

    enum State {
        case loading
        case ready
        case notReady
    }

    enum Mode {
        case send
        case predefined(address: String)
    }

    enum AmountError: Error {
        case invalidDecimal
        case insufficientBalance
    }

    enum AmountWarning {
        case coinNeededForFee
    }

}

struct SendBaseService {}

extension SendBaseService {

    enum State {
        case loading
        case ready
        case notReady
    }

    enum AmountError: Error {
        case invalidDecimal
        case insufficientBalance
    }

    enum AmountWarning {
        case coinNeededForFee
    }

}

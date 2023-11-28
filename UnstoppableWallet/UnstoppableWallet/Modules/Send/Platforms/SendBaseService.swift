import Foundation

struct SendBaseService {}

extension SendBaseService {
    enum State {
        case loading
        case ready
        case notReady
    }

    enum Mode {
        case send
        case prefilled(address: String, amount: Decimal?)
        case predefined(address: String)

        var amount: Decimal? {
            switch self {
            case let .prefilled(_, amount): return amount
            default: return nil
            }
        }
    }

    enum AmountError: Error {
        case invalidDecimal
        case insufficientBalance
    }

    enum AmountWarning {
        case coinNeededForFee
    }
}

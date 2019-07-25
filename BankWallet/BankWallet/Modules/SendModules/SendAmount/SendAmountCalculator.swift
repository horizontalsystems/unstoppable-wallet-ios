import Foundation

class SendAmountCalculator {

    func mainValue(amount: Decimal, inputType: SendInputType, rate: Rate?) -> Decimal {
        switch inputType {
        case .coin:
            return amount
        case .currency:
            return rate.map {
                return amount * $0.value
            } ?? 0
        }
    }

    func subValue(amount: Decimal, inputType: SendInputType, rate: Rate?) -> Decimal {
        switch inputType {
        case .coin:
            return rate.map {
                return amount * $0.value
            } ?? 0
        case .currency:
            return amount
        }
    }
}

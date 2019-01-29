import Foundation

struct PaymentRequestAddress {
    let address: String
    let amount: Decimal?

    init(address: String, amount: Decimal? = nil) {
        self.address = address
        self.amount = amount
    }

}

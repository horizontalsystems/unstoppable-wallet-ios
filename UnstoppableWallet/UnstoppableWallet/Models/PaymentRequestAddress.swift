import Foundation

struct PaymentRequestAddress {
    let address: String
    let amount: Decimal?
    let error: Error?

    init(address: String, amount: Decimal? = nil, error: Error? = nil) {
        self.address = address
        self.amount = amount
        self.error = error
    }

}

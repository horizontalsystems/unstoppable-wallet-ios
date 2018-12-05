import Foundation

struct PaymentRequestAddress {
    let address: String
    let amount: Double?

    init(address: String, amount: Double? = nil) {
        self.address = address
        self.amount = amount
    }

}

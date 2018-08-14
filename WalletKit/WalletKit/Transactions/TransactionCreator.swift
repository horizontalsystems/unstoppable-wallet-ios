import Foundation

class TransactionCreator {

    let feeRate: Int = 6
    let addressConverter: AddressConverter

    init(addressConverter: AddressConverter) {
        self.addressConverter = addressConverter
    }

    func create(to address: String, amount: Int) {

    }

}

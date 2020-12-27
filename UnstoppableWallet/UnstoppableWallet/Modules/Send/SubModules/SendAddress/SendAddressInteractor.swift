import Foundation

class SendAddressInteractor {
    private let addressParser: IAddressParser

    init(addressParser: IAddressParser) {
        self.addressParser = addressParser
    }

}

extension SendAddressInteractor: ISendAddressInteractor {

    func parse(address: String) -> (String, Decimal?) {
        let addressData = addressParser.parse(paymentAddress: address)
        return (addressData.address, addressData.amount.map { Decimal($0) })
    }

}

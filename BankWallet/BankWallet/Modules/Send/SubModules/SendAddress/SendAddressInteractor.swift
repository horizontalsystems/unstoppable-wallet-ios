import Foundation

class SendAddressInteractor {
    private let pasteboardManager: IPasteboardManager
    private let addressParser: IAddressParser

    init(pasteboardManager: IPasteboardManager, addressParser: IAddressParser) {
        self.pasteboardManager = pasteboardManager
        self.addressParser = addressParser
    }

}

extension SendAddressInteractor: ISendAddressInteractor {

    var valueFromPasteboard: String? {
        pasteboardManager.value
    }

    func parse(address: String) -> (String, Decimal?) {
        let addressData = addressParser.parse(paymentAddress: address)
        return (addressData.address, addressData.amount.map { Decimal($0) })
    }

}

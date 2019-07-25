class SendAddressInteractor {
    private let pasteboardManager: IPasteboardManager
    private let adapter: IAdapter

    init(pasteboardManager: IPasteboardManager, adapter: IAdapter) {
        self.pasteboardManager = pasteboardManager
        self.adapter = adapter
    }

}

extension SendAddressInteractor: ISendAddressInteractor {

    var valueFromPasteboard: String? {
        return pasteboardManager.value
    }

    func parse(paymentAddress: String) -> PaymentRequestAddress {
        return adapter.parse(paymentAddress: paymentAddress)
    }

    func validate(address: String) throws {
        do {
            try adapter.validate(address: address)
        } catch {
            throw AddressError.invalidAddress
        }
    }

}
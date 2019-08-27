import Foundation

class SendAddressPresenter {
    weak var view: ISendAddressView?
    weak var delegate: ISendAddressDelegate?

    private let interactor: ISendAddressInteractor
    private let router: ISendAddressRouter

    var currentAddress: String? {
        didSet {
            delegate?.onUpdateAddress()
        }
    }

    init(interactor: ISendAddressInteractor, router: ISendAddressRouter) {
        self.interactor = interactor
        self.router = router
    }

    private func onEnter(address: String) {
        let (parsedAddress, amount) = interactor.parse(address: address)

        do {
            try delegate?.validate(address: parsedAddress)

            view?.set(address: parsedAddress, error: nil)
            self.currentAddress = address

            if let amount = amount {
                delegate?.onUpdate(amount: amount)
            }
        } catch {
            view?.set(address: parsedAddress, error: error.localizedDescription)
            self.currentAddress = nil
        }
    }

}

extension SendAddressPresenter: ISendAddressViewDelegate {

    func onAddressScanClicked() {
        router.scanQrCode(delegate: self)
    }

    func onAddressPasteClicked() {
        if let address = interactor.valueFromPasteboard {
            onEnter(address: address)
        }
    }

    func onAddressDeleteClicked() {
        view?.set(address: nil, error: nil)
        currentAddress = nil
    }

}

extension SendAddressPresenter: ISendAddressModule {

    func validAddress() throws -> String {
        guard let validAddress = currentAddress else {
            throw ValidationError.invalidAddress
        }

        return validAddress
    }

}

extension SendAddressPresenter: IScanQrCodeDelegate {

    func didScan(string: String) {
        onEnter(address: string)
    }

}

extension SendAddressPresenter {

    private enum ValidationError: Error, LocalizedError {
        case invalidAddress

        var errorDescription: String? {
            switch self {
            case .invalidAddress:
                return "send.address_error.invalid_address".localized
            }
        }
    }

}

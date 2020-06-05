import Foundation
import Hodler

class SendAddressPresenter {
    weak var view: ISendAddressView?
    weak var delegate: ISendAddressDelegate?

    private let interactor: ISendAddressInteractor
    private let router: ISendAddressRouter

    private var enteredAddress: String?
    var currentAddress: String?

    init(interactor: ISendAddressInteractor, router: ISendAddressRouter) {
        self.interactor = interactor
        self.router = router
    }

    private func onEnter(address: String) {
        let (parsedAddress, amount) = interactor.parse(address: address)

        enteredAddress = parsedAddress
        try? validateAddress()

        delegate?.onUpdateAddress()
        if let amount = amount {
            delegate?.onUpdate(amount: amount)
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
        enteredAddress = nil
        delegate?.onUpdateAddress()
    }

}

extension SendAddressPresenter: ISendAddressModule {

    func validateAddress() throws {
        guard let address = enteredAddress else {
            currentAddress = nil
            throw AppError.addressInvalid
        }

        do {
            try delegate?.validate(address: address)
            currentAddress = address
            view?.set(address: address, error: nil)
        } catch {
            currentAddress = nil
            view?.set(address: address, error: error.convertedError)
            throw error
        }
    }

    func validAddress() throws -> String {
        guard let address = currentAddress else {
            throw AppError.addressInvalid
        }

        return address
    }

}

extension SendAddressPresenter: IScanQrModuleDelegate {

    func validate(string: String) throws {
        try delegate?.validate(address: string)
    }

    func didScan(string: String) {
        onEnter(address: string)
    }

}

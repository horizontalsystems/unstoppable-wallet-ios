import Foundation

class SendAddressPresenter {
    weak var view: ISendAddressView?
    weak var delegate: ISendAddressDelegate?

    private let interactor: ISendAddressInteractor

    var address: String? {
        didSet {
            delegate?.onUpdateAddress()
        }
    }

    init(interactor: ISendAddressInteractor) {
        self.interactor = interactor
    }

    private func onEnter(address: String) {
        let (parsedAddress, amount) = interactor.parse(address: address)

        do {
            try delegate?.validate(address: parsedAddress)

            view?.set(address: parsedAddress, error: nil)
            self.address = address

            if let amount = amount {
                delegate?.onUpdate(amount: amount)
            }
        } catch {
            view?.set(address: parsedAddress, error: error.localizedDescription)
            self.address = nil
        }
    }

}

extension SendAddressPresenter: ISendAddressViewDelegate {

    func onAddressScanClicked() {
        delegate?.scanQrCode(delegate: self)
    }

    func onAddressPasteClicked() {
        if let address = interactor.valueFromPasteboard {
            onEnter(address: address)
        }
    }

    func onAddressDeleteClicked() {
        view?.set(address: nil, error: nil)
        address = nil
    }

}

extension SendAddressPresenter: ISendAddressModule {
}

extension SendAddressPresenter: IScanQrCodeDelegate {

    func didScan(string: String) {
        onEnter(address: string)
    }

}

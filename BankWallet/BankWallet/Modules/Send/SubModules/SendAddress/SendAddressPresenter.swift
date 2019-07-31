import Foundation

class SendAddressPresenter {
    private let interactor: ISendAddressInteractor

    weak var view: ISendAddressView?
    weak var delegate: ISendAddressDelegate?

    var address: String?
    var invalidAddress: Error?

    init(interactor: ISendAddressInteractor) {
        self.interactor = interactor
    }

    private func onAddressEnter(address: String) {
        let paymentAddress = delegate?.parse(paymentAddress: address)
        if paymentAddress?.error != nil {
            view?.set(address: paymentAddress?.address, error: "Invalid address".localized)
            invalidAddress = paymentAddress?.error
            delegate?.onAddressUpdate(address: nil)
        } else {
            view?.set(address: paymentAddress?.address, error: nil)
            invalidAddress = nil
            self.address = address

            delegate?.onAddressUpdate(address: paymentAddress?.address)
            if let amount = paymentAddress?.amount {
                delegate?.onAmountUpdate(amount: amount)
            }
        }
    }

}

extension SendAddressPresenter: ISendAddressViewDelegate {

    func onAddressScanClicked() {
        delegate?.scanQrCode(delegate: self)
    }

    func onAddressPasteClicked() {
        if let address = interactor.valueFromPasteboard {
            onAddressEnter(address: address)
        }
    }

    func onAddressDeleteClicked() {
        view?.set(address: nil, error: nil)
        address = nil

        delegate?.onAddressUpdate(address: nil)
    }

}

extension SendAddressPresenter: ISendAddressModule {

    var validState: Bool {
        return (address != nil) && (invalidAddress == nil)
    }

}

extension SendAddressPresenter: IScanQrCodeDelegate {

    func didScan(string: String) {
        onAddressEnter(address: string)
    }

}

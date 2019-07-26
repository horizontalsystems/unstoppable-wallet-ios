import Foundation

class SendAddressPresenter {
    private let interactor: ISendAddressInteractor
    private let router: ISendAddressRouter

    weak var view: ISendAddressView?
    weak var presenterDelegate: ISendAddressPresenterDelegate?

    var address: String?

    init(interactor: ISendAddressInteractor, router: ISendAddressRouter) {
        self.interactor = interactor
        self.router = router
    }

    private func onAddressEnter(address: String) {
        let paymentAddress = presenterDelegate?.parse(paymentAddress: address)
        if paymentAddress?.error != nil {
            view?.set(address: paymentAddress?.address, error: "Invalid address".localized)
            presenterDelegate?.onAddressUpdate(address: nil)
        } else {
            view?.set(address: paymentAddress?.address, error: nil)
            self.address = address

            presenterDelegate?.onAddressUpdate(address: paymentAddress?.address)
            if let amount = paymentAddress?.amount {
                presenterDelegate?.onAmountUpdate(amount: amount)
            }
        }
    }

}

extension SendAddressPresenter: ISendAddressViewDelegate {

    func onAddressScanClicked() {
        router.scanQrCode(onCodeParse: { [weak self] address in
            self?.onAddressEnter(address: address)
        })
    }

    func onAddressPasteClicked() {
        if let address = interactor.valueFromPasteboard {
            onAddressEnter(address: address)
        }
    }

    func onAddressDeleteClicked() {
        view?.set(address: nil, error: nil)
        address = nil

        presenterDelegate?.onAddressUpdate(address: nil)
    }

}

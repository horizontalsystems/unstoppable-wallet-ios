import Foundation

class SendAddressPresenter {
    private let interactor: ISendAddressInteractor
    private let router: ISendAddressRouter

    weak var view: ISendAddressView?
    weak var presenterDelegate: ISendAddressPresenterDelegate?

    init(interactor: ISendAddressInteractor, router: ISendAddressRouter) {
        self.interactor = interactor
        self.router = router
    }

    private func onAddressEnter(address: String) {
        let paymentAddress = interactor.parse(paymentAddress: address)
        do {
            try interactor.validate(address: paymentAddress.address)
            view?.set(address: paymentAddress.address, error: nil)

            presenterDelegate?.onAddressUpdate(address: paymentAddress.address)
            if let amount = paymentAddress.amount {
                presenterDelegate?.onAmountUpdate(amount: amount)
            }
        } catch {
            view?.set(address: paymentAddress.address, error: "Invalid address".localized)
            presenterDelegate?.onAddressUpdate(address: nil)
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

        presenterDelegate?.onAddressUpdate(address: nil)
    }

}

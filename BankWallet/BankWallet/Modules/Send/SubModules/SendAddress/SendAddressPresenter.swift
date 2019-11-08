import Foundation
import Hodler

class SendAddressPresenter {
    weak var view: ISendAddressView?
    weak var delegate: ISendAddressDelegate?

    private let interactor: ISendAddressInteractor
    private let router: ISendAddressRouter

    private var enteredAddress: String?

    var currentAddress: String? {
        do {
            return try validAddress()
        } catch {
            return nil
        }
    }

    init(interactor: ISendAddressInteractor, router: ISendAddressRouter) {
        self.interactor = interactor
        self.router = router
    }

    private func onEnter(address: String) {
        let (parsedAddress, amount) = interactor.parse(address: address)

        enteredAddress = parsedAddress
        _ = try? validAddress()

        delegate?.onUpdateAddress()
        if let amount = amount {
            delegate?.onUpdate(amount: amount)
        }
    }

    private func createSendError(from error: Error) -> Error {
        if let error = error as? HodlerPluginError, error == HodlerPluginError.unsupportedAddress {
            return ValidationError.notSupportedByHodler
        }

        return ValidationError.invalidAddress
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

    func validAddress() throws -> String {
        guard let address = enteredAddress else {
            throw ValidationError.invalidAddress
        }

        do {
            try delegate?.validate(address: address)
            view?.set(address: address, error: nil)
        } catch {
            view?.set(address: address, error: createSendError(from: error))
            throw error
        }

        return address
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
        case notSupportedByHodler

        var errorDescription: String? {
            switch self {
            case .invalidAddress:
                return "send.error.invalid_address".localized
            case .notSupportedByHodler:
                return "send.hodler_error.unsupported_address".localized
            }
        }
    }

}

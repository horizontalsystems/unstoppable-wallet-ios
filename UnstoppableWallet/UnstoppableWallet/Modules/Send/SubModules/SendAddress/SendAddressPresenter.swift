import Foundation
import Hodler
import RxSwift
import RxRelay

class SendAddressPresenter {
    weak var delegate: ISendAddressDelegate?

    private let router: ISendAddressRouter

    private var enteredAddress: Address?
    var currentAddress: Address?

    private(set) var error: Error? {
        didSet {
            errorRelay.accept(error)
        }
    }
    private let errorRelay = PublishRelay<Error?>()

    init(router: ISendAddressRouter) {
        self.router = router
    }

    private func onEnter(address: Address) {
        enteredAddress = address
        try? validateAddress()

        delegate?.onUpdateAddress()
    }

    private func onSet(address: Address?) {
        guard let address = address, !address.raw.isEmpty else {
            error = nil
            currentAddress = nil
            enteredAddress = nil
            delegate?.onUpdateAddress()

            return
        }

        onEnter(address: address)
    }

}

extension SendAddressPresenter: ISendAddressViewDelegate {

    func onOpenScan(controller: UIViewController) {
        router.openScan(controller: controller)
    }

}

extension SendAddressPresenter: ISendAddressModule {

    func validateAddress() throws {
        guard let address = enteredAddress else {
            currentAddress = nil
            throw ValidationError.emptyValue
        }

        do {
            try delegate?.validate(address: address.raw)
            currentAddress = address
            error = nil
        } catch {
            currentAddress = nil
            self.error = error.convertedError
            throw error
        }
    }

    func validAddress() throws -> Address {
        guard let address = currentAddress else {
            throw ValidationError.emptyValue
        }

        return address
    }

}

extension SendAddressPresenter: IRecipientAddressService {

    var initialAddress: Address? {
        nil
    }

    var errorObservable: Observable<Error?> {
        errorRelay.asObservable()
    }

    func set(address: Address?) {
        DispatchQueue.main.async { [weak self] in
            self?.onSet(address: address)
        }
    }

    func set(amount: Decimal) {
        delegate?.onUpdate(amount: amount)
    }

}

extension SendAddressPresenter {

    enum ValidationError: Error {
        case emptyValue
    }

}

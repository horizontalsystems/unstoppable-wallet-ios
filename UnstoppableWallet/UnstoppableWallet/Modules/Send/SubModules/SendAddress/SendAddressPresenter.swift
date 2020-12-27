import Foundation
import Hodler
import RxSwift
import RxRelay

class SendAddressPresenter {
    weak var delegate: ISendAddressDelegate?

    private let interactor: ISendAddressInteractor
    private let router: ISendAddressRouter

    private var enteredAddress: String?
    var currentAddress: String?

    private(set) var error: Error? {
        didSet {
            errorRelay.accept(error)
        }
    }
    private let errorRelay = PublishRelay<Error?>()

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

    func onOpenScan(controller: UIViewController) {
        router.openScan(controller: controller)
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
            error = nil
        } catch {
            currentAddress = nil
            self.error = error.convertedError
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

extension SendAddressPresenter: IRecipientAddressService {

    var initialAddress: Address? {
        nil
    }

    var errorObservable: Observable<Error?> {
        errorRelay.asObservable()
    }

    func set(address: Address?) {
        guard let address = address?.raw, !address.isEmpty else {
            error = nil
            currentAddress = nil
            enteredAddress = nil
            delegate?.onUpdateAddress()

            return
        }

        onEnter(address: address)
    }

}

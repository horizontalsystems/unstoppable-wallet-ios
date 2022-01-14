import Foundation
import Hodler
import RxSwift
import RxRelay

class SendAddressPresenter {
    weak var delegate: ISendAddressDelegate?

    private let router: ISendAddressRouter

    var currentAddress: Address?

    private(set) var recipientError: Error? {
        didSet {
            errorRelay.accept(recipientError)
        }
    }
    private let errorRelay = PublishRelay<Error?>()

    init(router: ISendAddressRouter) {
        self.router = router
    }

    private func onSet(address: Address?) {
        guard let address = address, !address.raw.isEmpty else {
            recipientError = nil
            currentAddress = nil
            delegate?.onUpdateAddress()

            return
        }

        currentAddress = address

        delegate?.onUpdateAddress()
    }

}

extension SendAddressPresenter: ISendAddressViewDelegate {

    func onOpenScan(controller: UIViewController) {
        router.openScan(controller: controller)
    }

}

extension SendAddressPresenter: ISendAddressModule {

    func validAddress() throws -> Address {
        guard let address = currentAddress else {
            throw ValidationError.emptyValue
        }

        return address
    }

}

extension SendAddressPresenter: IRecipientAddressService {

    var addressState: AddressService.State {
        .empty
    }

    var addressStateObservable: Observable<AddressService.State> {
        Observable.just(.empty)
    }

    var recipientErrorObservable: Observable<Error?> {
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

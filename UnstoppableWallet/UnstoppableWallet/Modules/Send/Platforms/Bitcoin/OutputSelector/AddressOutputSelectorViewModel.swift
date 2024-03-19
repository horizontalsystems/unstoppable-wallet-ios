import Combine
import RxSwift

class AddressOutputSelectorViewModel: ObservableObject {
    let disposeBag = DisposeBag()
    let addressService: AddressService

    @Published var address: String? = nil

    init(addressService: AddressService) {
        self.addressService = addressService

        subscribe(disposeBag, addressService.stateObservable) { [weak self] _ in self?.updateAddress() }
        updateAddress()
    }

    private func updateAddress() {
        guard case let .success(address) = addressService.state else {
            address = nil
            return
        }

        self.address = address.raw.shortened
    }
}

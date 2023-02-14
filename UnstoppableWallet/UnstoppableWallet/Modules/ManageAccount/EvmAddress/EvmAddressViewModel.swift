class EvmAddressViewModel {
    private let service: EvmAddressService

    init(service: EvmAddressService) {
        self.service = service
    }

}

extension EvmAddressViewModel {

    var address: String {
        service.address
    }

}

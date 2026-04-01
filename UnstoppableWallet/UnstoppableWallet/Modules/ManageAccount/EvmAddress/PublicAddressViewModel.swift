class PublicAddressViewModel {
    private let service: IPublicAddressService

    init(service: IPublicAddressService) {
        self.service = service
    }
}

extension PublicAddressViewModel {
    var address: String {
        service.address
    }
}

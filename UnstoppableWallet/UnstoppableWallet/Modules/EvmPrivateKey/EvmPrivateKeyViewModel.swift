class EvmPrivateKeyViewModel {
    private let service: EvmPrivateKeyService

    init(service: EvmPrivateKeyService) {
        self.service = service
    }

}

extension EvmPrivateKeyViewModel {

    var privateKey: String {
        service.privateKey
    }

}

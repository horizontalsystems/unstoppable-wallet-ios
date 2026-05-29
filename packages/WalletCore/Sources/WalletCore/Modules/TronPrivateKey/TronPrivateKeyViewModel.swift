class TronPrivateKeyViewModel {
    private let service: TronPrivateKeyService

    init(service: TronPrivateKeyService) {
        self.service = service
    }
}

extension TronPrivateKeyViewModel {
    var privateKey: String {
        service.privateKey
    }
}

import Foundation

class PublicKeysViewModel {
    private let service: PublicKeysService

    init(service: PublicKeysService) {
        self.service = service
    }

}

extension PublicKeysViewModel {

    var accountType: AccountType {
        service.accountType
    }

    var showEvmAddress: Bool {
        service.evmAddressSupported
    }

    var showAccountExtendedPublicKey: Bool {
        service.accountExtendedPublicKeySupported
    }

}

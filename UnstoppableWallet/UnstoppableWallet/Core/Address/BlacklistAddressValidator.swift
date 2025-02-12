import EvmKit
import HsToolKit
import MarketKit

class BlacklistAddressValidator {
    private let hashDitAddressValidator = HashDitAddressValidator()
    private let eip20AddressValidator = Eip20AddressValidator()
}

extension BlacklistAddressValidator: IAddressSecurityChecker {
    func check(address: Address, token: Token) async throws -> Bool {
        async let hashDitResult = hashDitAddressValidator.check(address: address, token: token)
        async let smartContractResult = eip20AddressValidator.check(address: address, token: token)

        let (blacklistedInHashDit, blacklistedInSmartContract) = try await (hashDitResult, smartContractResult)

        return blacklistedInHashDit || blacklistedInSmartContract
    }
}

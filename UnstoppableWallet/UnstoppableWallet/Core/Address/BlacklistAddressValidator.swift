import EvmKit
import HsToolKit
import MarketKit

class BlacklistAddressValidator {
    private let hashDitAddressValidator = HashDitAddressValidator()
    private let eip20AddressValidator = Eip20AddressValidator()
}

extension BlacklistAddressValidator: IAddressSecurityChecker {
    func isClear(address: Address, token: Token) async throws -> Bool {
        async let hashDitResult = hashDitAddressValidator.isClear(address: address, token: token)
        async let smartContractResult = eip20AddressValidator.isClear(address: address, token: token)

        let (hashDitClear, smartContractClear) = try await (hashDitResult, smartContractResult)

        return hashDitClear && smartContractClear
    }
}

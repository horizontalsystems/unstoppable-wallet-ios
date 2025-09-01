import EvmKit
import HsToolKit
import MarketKit

class BlacklistAddressValidator {
    private var validators = [IAddressSecurityChecker]()

    init() {
        validators.append(HashDitAddressValidator())
        validators.append(Core.shared.contractAddressValidator)
    }
}

extension BlacklistAddressValidator: IAddressSecurityChecker {
    func isClear(address: Address, token: Token) async throws -> Bool {
        var lastError: Error?
        var result: Bool?
        for validator in validators {
            do {
                let isClear = try await validator.isClear(address: address, token: token)
                if let previous = result {
                    result = previous && isClear
                } else {
                    result = isClear
                }
            } catch {
                lastError = error
            }
        }

        if let result {
            return result
        }

        throw lastError ?? CheckError.noValidators
    }
}

extension BlacklistAddressValidator {
    enum CheckError: Error {
        case noValidators
    }
}

import Foundation
import HdWalletKit
import EvmKit

class RestorePrivateKeyService {

    func accountType(text: String) throws -> AccountType {
        let text = text.trimmingCharacters(in: .whitespaces)

        guard !text.isEmpty else {
            throw RestoreError.emptyText
        }

        do {
            let extendedKey = try HDExtendedKey(extendedKey: text)

            switch extendedKey {
            case .private:
                switch extendedKey.derivedType {
                case .master, .account:
                    return .hdExtendedKey(key: extendedKey)
                default:
                    throw RestoreError.notSupportedDerivedType
                }
            default:
                throw RestoreError.nonPrivateKey
            }
        } catch {
        }

        do {
            let privateKey = try Signer.privateKey(string: text)
            return .evmPrivateKey(data: privateKey)
        } catch {
        }

        throw RestoreError.noValidKey
    }

}

extension RestorePrivateKeyService {

    enum RestoreError: Error {
        case emptyText
        case notSupportedDerivedType
        case nonPrivateKey
        case noValidKey
    }

}

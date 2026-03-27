import EvmKit
import Foundation
import HdWalletKit
import stellarsdk
import TronKit

class RestorePrivateKeyService {
    func accountType(text: String) throws -> [AccountType] {
        let text = text.trimmingCharacters(in: .whitespaces)

        guard !text.isEmpty else {
            throw RestoreError.emptyText
        }

        var accountTypes = [AccountType]()

        do {
            let extendedKey = try HDExtendedKey(extendedKey: text)

            switch extendedKey {
            case .private:
                switch extendedKey.derivedType {
                case .master, .account:
                    accountTypes.append(.hdExtendedKey(key: extendedKey))
                default:
                    throw RestoreError.notSupportedDerivedType
                }
            default:
                throw RestoreError.nonPrivateKey
            }
        } catch {}

        do {
            let privateKey = try EvmKit.Signer.privateKey(string: text)
            accountTypes.append(.evmPrivateKey(data: privateKey))
        } catch {}

        do {
            let privateKey = try TronKit.Signer.privateKey(string: text)
            accountTypes.append(.trcPrivateKey(data: privateKey))
        } catch {}

        do {
            _ = try KeyPair(secretSeed: text)
            accountTypes.append(.stellarSecretKey(secretSeed: text))
        } catch {}

        if !accountTypes.isEmpty {
            return accountTypes
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

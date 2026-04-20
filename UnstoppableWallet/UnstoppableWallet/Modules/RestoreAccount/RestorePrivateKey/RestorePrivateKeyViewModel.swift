import Combine
import EvmKit
import Foundation
import HdWalletKit
import MarketKit
import stellarsdk
import TronKit

class RestorePrivateKeyViewModel: ObservableObject {
    private let accountFactory = Core.shared.accountFactory

    @Published var name: String
    @Published var privateKeyCaution: CautionState = .none

    let proceedSubject = PassthroughSubject<(String, [AccountType]), Never>()

    private var text = ""

    init() {
        name = accountFactory.nextAccountName
    }

    private var resolvedName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? accountFactory.nextAccountName : trimmed
    }

    func onChange(privateKey: String) {
        text = privateKey
        privateKeyCaution = .none
    }

    func onTapProceed() {
        if let accountTypes = resolveAccountTypes() {
            proceedSubject.send((resolvedName, accountTypes))
        }
    }

    private func resolveAccountTypes() -> [AccountType]? {
        privateKeyCaution = .none

        do {
            return try accountTypes(text: text)
        } catch {
            privateKeyCaution = .caution(Caution(text: "restore.private_key.invalid_key".localized, type: .error))
            return nil
        }
    }

    private func accountTypes(text: String) throws -> [AccountType] {
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

extension RestorePrivateKeyViewModel {
    enum RestoreError: Error {
        case emptyText
        case notSupportedDerivedType
        case nonPrivateKey
        case noValidKey
    }
}

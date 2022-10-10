import StorageKit
import EvmKit

class ProFeaturesStorage {
    private let secureStorage: ISecureStorage

    init(secureStorage: ISecureStorage) {
        self.secureStorage = secureStorage
    }

}

extension ProFeaturesStorage {

    func getAll() -> [ProFeaturesAuthorizationManager.NftType: SessionKey] {
        var keys = [ProFeaturesAuthorizationManager.NftType: SessionKey]()
        for type in ProFeaturesAuthorizationManager.NftType.allCases {
            if let raw: String = secureStorage.value(for: type.rawValue),
               let sessionKey = SessionKey(raw: raw) {
                keys[type] = sessionKey
            }
        }

        return keys
    }

    func get(type: ProFeaturesAuthorizationManager.NftType) -> SessionKey? {
        let raw: String? = secureStorage.value(for: type.rawValue)
        return raw.flatMap { SessionKey(raw: $0) }
    }

    func save(type: ProFeaturesAuthorizationManager.NftType, key: SessionKey) {
        try? secureStorage.set(value: key.rawValue, for: type.rawValue)
    }

    func delete(accountId: String) {
        let keys = getAll()
        for key in keys {
            if key.value.accountId == accountId {
                try? secureStorage.removeValue(for: key.key.rawValue)
            }
        }
    }

    func clear(type: ProFeaturesAuthorizationManager.NftType?) {
        if let type = type {
            try? secureStorage.removeValue(for: type.rawValue)
            return
        }

        for type in ProFeaturesAuthorizationManager.NftType.allCases {
            try? secureStorage.removeValue(for: type.rawValue)
        }
    }

}

extension ProFeaturesStorage {

    struct SessionKey: CustomStringConvertible {
        private static let separator: Character = "_"

        let accountId: String
        let address: String
        let sessionKey: String

        init(accountId: String, address: String, sessionKey: String) {
            self.accountId = accountId
            self.address = address
            self.sessionKey = sessionKey
        }

        init?(raw: String) {
            let values = raw.split(separator: SessionKey.separator).map { String($0) }
            guard values.count == 3 else {
                return nil
            }

            accountId = values[0]
            address = values[1]
            sessionKey = values[2]
        }

        var rawValue: String {
            [accountId, address, sessionKey].joined(separator: String(SessionKey.separator))
        }

    }

}


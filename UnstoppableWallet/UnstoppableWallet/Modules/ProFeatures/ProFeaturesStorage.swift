import StorageKit
import EthereumKit

class ProFeaturesStorage {
    private let secureStorage: ISecureStorage

    init(secureStorage: ISecureStorage) {
        self.secureStorage = secureStorage
    }

}

extension ProFeaturesStorage {

    func getAll() -> [NFTType: SessionKey] {
        var keys = [NFTType: SessionKey]()
        for type in NFTType.allCases {
            if let raw: String = secureStorage.value(for: type),
               let sessionKey = SessionKey(raw: raw) {
                keys[type] = sessionKey
            }
        }

        return keys
    }

    func get(type: NFTType) -> SessionKey? {
        let raw: String? = secureStorage.value(for: type)
        return raw.map { SessionKey(raw: $0) }
    }

    func save(type: NFTType, key: SessionKey) {
        secureStorage.set(value: key.rawValue, for: type)
    }

    func delete(accountId: String) {
        let keys = getAll()
        for key in keys {
            if key.value.accountId == accountId {
                try? secureStorage.removeValue(for: key.key)
            }
        }
    }

    func clear() {
        for type in NFTType {
            try? secureStorage.removeValue(for: type)
        }
    }

}

extension ProFeaturesStorage {

    struct SessionKey: CustomStringConvertible {
        private static let separator = "_"

        let accountId: String
        let address: String
        let sessionKey: String

        init?(raw: String) {
            let values = raw.split(separator: SessionKey.separator)
            guard values.count == 3 else {
                return nil
            }

            accountId = values[0]
            address = values[1]
            sessionKey = values[2]
        }

        var rawValue: String {
            [accountId, address, sessionKey].joined(separator: SessionKey.separator)
        }

    }

    enum NFTType: String, CaseIterable {
        case mountainYak
    }

}


import Foundation

struct FullBackup {
    let id: String
    let wallets: [CloudRestoreBackupListModule.RestoredBackup]
    let watchlistIds: [String]
    let contacts: BackupCrypto?
    let settings: SettingsBackup
    let sections: Set<BackupSection>?
    let version: Int
    let timestamp: TimeInterval?
    // number of wallet entries in the file before unknown types were dropped; not part of the format
    var rawWalletCount: Int = 0
}

extension FullBackup: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case wallets
        case watchlistIds = "watchlist"
        case contacts
        case settings
        case sections
        case version
        case timestamp
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        if container.contains(.wallets) {
            // entries of an unknown type are dropped here; the original count tells a file whose accounts
            // were all skipped from a file that simply carries no accounts. A broken array is an error:
            // silently restoring nothing would look like a successful restore of an empty backup
            let decoded = try container.decode([FailableDecodable<CloudRestoreBackupListModule.RestoredBackup>].self, forKey: .wallets)
            rawWalletCount = decoded.count
            wallets = decoded.compactMap(\.base)
        } else {
            rawWalletCount = 0
            wallets = []
        }
        watchlistIds = (try? container.decode([String].self, forKey: .watchlistIds)) ?? []
        contacts = try? container.decode(BackupCrypto.self, forKey: .contacts)
        settings = try container.decode(SettingsBackup.self, forKey: .settings)
        sections = try? container.decode(Set<BackupSection>.self, forKey: .sections)
        version = try container.decode(Int.self, forKey: .version)
        timestamp = try? container.decode(TimeInterval.self, forKey: .timestamp)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        if !wallets.isEmpty { try container.encode(wallets, forKey: .wallets) }
        if !watchlistIds.isEmpty { try container.encode(watchlistIds, forKey: .watchlistIds) }
        if let contacts { try container.encode(contacts, forKey: .contacts) }
        try container.encode(settings, forKey: .settings)
        if let sections { try container.encode(sections, forKey: .sections) }
        try container.encode(version, forKey: .version)
        try? container.encode(timestamp, forKey: .timestamp)
    }
}

struct FailableDecodable<Base: Decodable>: Decodable {
    let base: Base?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        base = try? container.decode(Base.self)
    }
}

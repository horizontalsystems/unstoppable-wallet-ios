import Foundation

struct FullBackup {
    let id: String
    let wallets: [RestoreCloudModule.RestoredBackup]
    let watchlistIds: [String]
    let contacts: BackupCrypto?
    let settings: SettingsBackup
    let version: Int
    let timestamp: TimeInterval?
}

extension FullBackup: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case wallets
        case watchlistIds = "watchlist"
        case contacts
        case settings
        case version
        case timestamp
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        do {
            wallets = (try container.decode([FailableDecodable<RestoreCloudModule.RestoredBackup>].self, forKey: .wallets))
                .compactMap { $0.base }
        } catch {
            wallets = []
        }
        watchlistIds = (try? container.decode([String].self, forKey: .watchlistIds)) ?? []
        contacts = try? container.decode(BackupCrypto.self, forKey: .contacts)
        settings = try container.decode(SettingsBackup.self, forKey: .settings)
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
        try container.encode(version, forKey: .version)
        try? container.encode(timestamp, forKey: .timestamp)
    }
}

struct FailableDecodable<Base : Decodable> : Decodable {

    let base: Base?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        base = try? container.decode(Base.self)
    }
}

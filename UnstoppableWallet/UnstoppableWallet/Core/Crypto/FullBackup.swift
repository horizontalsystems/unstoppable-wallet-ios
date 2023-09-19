import Foundation

struct FullBackup {
    let id: String
    let wallets: [RestoreCloudModule.RestoredBackup]
    let watchlistIds: [String]
    let contacts: BackupCrypto?
    let settings: SettingsBackup?
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

//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        wallets = (try? container.decode([RestoreCloudModule.RestoredBackup].self, forKey: .wallets)) ?? []
//        watchlistIds = (try? container.decode([String].self, forKey: .watchlistIds)) ?? []
//        contacts = try? container.decode([BackupContact].self, forKey: .contacts)
//        evmSyncSources = try? container.decode(SyncSourceBackup.self, forKey: .evmSyncSources)
//        settings = try? container.decode(SettingsBackup.self, forKey: .settings)
//    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        if !wallets.isEmpty { try container.encode(wallets, forKey: .wallets) }
        if !watchlistIds.isEmpty { try container.encode(watchlistIds, forKey: .watchlistIds) }
        if let contacts { try container.encode(contacts, forKey: .contacts) }
        if let settings { try container.encode(settings, forKey: .settings) }
        try container.encode(version, forKey: .version)
        try container.encode(version, forKey: .version)
        try? container.encode(timestamp, forKey: .timestamp)
    }
}

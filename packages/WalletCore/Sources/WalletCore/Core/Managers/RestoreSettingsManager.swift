import Foundation
import MarketKit
import MoneroKit
import ZanoKit
import ZcashLightClientKit

public class RestoreSettingsManager {
    private let storage: RestoreSettingsStorage

    public init(storage: RestoreSettingsStorage) {
        self.storage = storage
    }
}

extension RestoreSettingsManager {
    func settings(accountId: String, blockchainType: BlockchainType) -> RestoreSettings {
        let records = storage.restoreSettings(accountId: accountId, blockchainUid: blockchainType.uid)

        var settings = RestoreSettings()

        for record in records {
            if let type = RestoreSettingType(rawValue: record.key) {
                settings[type] = record.value
            }
        }

        return settings
    }

    func accountSettingsInfo(account: Account) -> [(BlockchainType, RestoreSettingType, String)] {
        let records = storage.restoreSettings(accountId: account.id)

        return records.compactMap { record in
            guard let settingType = RestoreSettingType(rawValue: record.key) else {
                return nil
            }
            let blockchainType = BlockchainType(uid: record.blockchainUid)

            return (blockchainType, settingType, record.value)
        }
    }

    func save(settings: RestoreSettings, account: Account, blockchainType: BlockchainType) {
        let records = settings.map { type, value in
            RestoreSettingRecord(accountId: account.id, blockchainUid: blockchainType.uid, key: type.rawValue, value: value)
        }

        storage.save(restoreSettingRecords: records)
    }

    // Enabling a chain that needs restore settings without recording them leaves the adapter
    // on its worst-case fallback (a restored account scans Zcash from Sapling activation).
    // Flows that ask the user save their values before the wallet, so this only fills gaps
    // with the "wallet is new" defaults.
    func saveDefaultSettingsIfNeeded(account: Account, blockchainType: BlockchainType) {
        let existingSettings = settings(accountId: account.id, blockchainType: blockchainType)
        var defaultSettings = RestoreSettings()

        for type in blockchainType.restoreSettingTypes where existingSettings[type] == nil {
            defaultSettings[type] = type.createdAccountValue(blockchainType: blockchainType)
        }

        if !defaultSettings.isEmpty {
            save(settings: defaultSettings, account: account, blockchainType: blockchainType)
        }
    }
}

enum RestoreSettingType: String {
    case birthdayHeight = "birthday_height"

    func createdAccountValue(blockchainType: BlockchainType) -> String? {
        switch self {
        case .birthdayHeight:
            switch blockchainType {
            case .zcash: return "\(ZcashAdapter.newBirthdayHeight(network: ZcashNetworkBuilder.network(for: ZcashAdapter.networkType)))"
            case .monero: return "\(MoneroKit.RestoreHeight.getHeight(date: Date()))"
            case .zano: return "\(ZanoKit.RestoreHeight.getHeight(date: Date()))"
            default: return nil
            }
        }
    }

    func title(coin: Coin) -> String {
        switch self {
        case .birthdayHeight: return "restore_setting.birthday_height".localized(coin.code)
        }
    }
}

typealias RestoreSettings = [RestoreSettingType: String]

extension RestoreSettings {
    var birthdayHeight: Int? {
        // a negative value would trap in UInt64() when an adapter starts; treat it as absent
        self[.birthdayHeight].flatMap { Int($0) }.flatMap { $0 >= 0 ? $0 : nil }
    }
}

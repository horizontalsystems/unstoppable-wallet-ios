import MarketKit
import ZcashLightClientKit

class RestoreSettingsManager {
    private let storage: RestoreSettingsStorage

    init(storage: RestoreSettingsStorage) {
        self.storage = storage
    }

}

extension RestoreSettingsManager {

    func settings(account: Account, blockchainType: BlockchainType) -> RestoreSettings {
        let records = storage.restoreSettings(accountId: account.id, blockchainUid: blockchainType.uid)

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

}

enum RestoreSettingType: String {
    case birthdayHeight

    func createdAccountValue(blockchainType: BlockchainType) -> String? {
        switch self {
        case .birthdayHeight:
            switch blockchainType {
            case .zcash: return "\(ZcashAdapter.newBirthdayHeight(network: ZcashNetworkBuilder.network(for: .mainnet)))"
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
        self[.birthdayHeight].flatMap { Int($0) }
    }

}

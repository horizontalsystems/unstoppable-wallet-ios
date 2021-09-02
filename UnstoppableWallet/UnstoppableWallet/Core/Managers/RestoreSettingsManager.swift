import MarketKit
import ZcashLightClientKit

class RestoreSettingsManager {
    private let storage: IRestoreSettingsStorage

    init(storage: IRestoreSettingsStorage) {
        self.storage = storage
    }

}

extension RestoreSettingsManager {

    func settings(account: Account, coinType: CoinType) -> RestoreSettings {
        let records = storage.restoreSettings(accountId: account.id, coinId: coinType.id)

        var settings = RestoreSettings()

        for record in records {
            if let type = RestoreSettingType(rawValue: record.key) {
                settings[type] = record.value
            }
        }

        return settings
    }

    func accountSettingsInfo(account: Account) -> [(CoinType, RestoreSettingType, String)] {
        let records = storage.restoreSettings(accountId: account.id)

        return records.compactMap { record in
            guard let settingType = RestoreSettingType(rawValue: record.key) else {
                return nil
            }
            let coinType = CoinType(id: record.coinId)

            return (coinType, settingType, record.value)
        }
    }

    func save(settings: RestoreSettings, account: Account, coinType: CoinType) {
        let records = settings.map { type, value in
            RestoreSettingRecord(accountId: account.id, coinId: coinType.id, key: type.rawValue, value: value)
        }

        storage.save(restoreSettingRecords: records)
    }

}

enum RestoreSettingType: String {
    case birthdayHeight

    func createdAccountValue(coinType: CoinType) -> String? {
        switch self {
        case .birthdayHeight:
            switch coinType {
            case .zcash: return "\(ZcashNetworkBuilder.network(for: .mainnet))"     // FIX: get real network
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

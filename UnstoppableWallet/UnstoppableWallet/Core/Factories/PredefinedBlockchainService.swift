import MarketKit

class PredefinedBlockchainService {
    private let restoreSettingsManager: RestoreSettingsManager

    init(restoreSettingsManager: RestoreSettingsManager) {
        self.restoreSettingsManager = restoreSettingsManager
    }

}

extension PredefinedBlockchainService {

    func prepareNew(account: Account, blockchainType: BlockchainType) {
        var restoreSettings: RestoreSettings = [:]

        switch blockchainType {
        case .zcash:
            if let birthdayHeight = RestoreSettingType.birthdayHeight.createdAccountValue(blockchainType: blockchainType) {
                restoreSettings[.birthdayHeight] = birthdayHeight
            }
        default: ()
        }

        if !restoreSettings.isEmpty {
            restoreSettingsManager.save(settings: restoreSettings, account: account, blockchainType: blockchainType)
        }
    }

}

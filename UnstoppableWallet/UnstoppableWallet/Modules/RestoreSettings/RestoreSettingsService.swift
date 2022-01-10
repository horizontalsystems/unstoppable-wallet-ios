import RxSwift
import RxRelay
import MarketKit

class RestoreSettingsService {
    private let manager: RestoreSettingsManager

    private let approveSettingsRelay = PublishRelay<CoinWithSettings>()
    private let rejectApproveSettingsRelay = PublishRelay<PlatformCoin>()

    private let requestRelay = PublishRelay<Request>()

    init(manager: RestoreSettingsManager) {
        self.manager = manager
    }

}

extension RestoreSettingsService {

    var approveSettingsObservable: Observable<CoinWithSettings> {
        approveSettingsRelay.asObservable()
    }

    var rejectApproveSettingsObservable: Observable<PlatformCoin> {
        rejectApproveSettingsRelay.asObservable()
    }

    var requestObservable: Observable<Request> {
        requestRelay.asObservable()
    }

    func approveSettings(platformCoin: PlatformCoin, account: Account? = nil) {
        let coinType = platformCoin.coinType

        if let account = account, case .created = account.origin {
            var settings = RestoreSettings()

            for type in coinType.restoreSettingTypes {
                settings[type] = type.createdAccountValue(coinType: coinType)
            }

            approveSettingsRelay.accept(CoinWithSettings(platformCoin: platformCoin, settings: settings))
            return
        }

        let existingSettings = account.map { manager.settings(account: $0, coinType: coinType) } ?? [:]

        if coinType.restoreSettingTypes.contains(.birthdayHeight) && existingSettings[.birthdayHeight] == nil {
            let request = Request(
                    platformCoin: platformCoin,
                    type: .birthdayHeight
            )

            requestRelay.accept(request)
            return
        }

        approveSettingsRelay.accept(CoinWithSettings(platformCoin: platformCoin, settings: [:]))
    }

    func save(settings: RestoreSettings, account: Account, coinType: CoinType) {
        manager.save(settings: settings, account: account, coinType: coinType)
    }

    func enter(birthdayHeight: Int, platformCoin: PlatformCoin) {
        var settings = RestoreSettings()
        settings[.birthdayHeight] = String(birthdayHeight)

        let coinWithSettings = CoinWithSettings(platformCoin: platformCoin, settings: settings)
        approveSettingsRelay.accept(coinWithSettings)
    }

    func cancel(platformCoin: PlatformCoin) {
        rejectApproveSettingsRelay.accept(platformCoin)
    }

}

extension RestoreSettingsService {

    struct CoinWithSettings {
        let platformCoin: PlatformCoin
        let settings: RestoreSettings
    }

    struct Request {
        let platformCoin: PlatformCoin
        let type: RequestType
    }

    enum RequestType {
        case birthdayHeight
    }

}

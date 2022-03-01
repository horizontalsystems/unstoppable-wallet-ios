import RxSwift
import RxRelay
import MarketKit

class EnableCoinService {
    private let coinPlatformsService: CoinPlatformsService
    private let restoreSettingsService: RestoreSettingsService
    private let coinSettingsService: CoinSettingsService
    private let disposeBag = DisposeBag()

    private let enableCoinRelay = PublishRelay<([ConfiguredPlatformCoin], RestoreSettings)>()
    private let cancelEnableCoinRelay = PublishRelay<FullCoin>()

    init(coinPlatformsService: CoinPlatformsService, restoreSettingsService: RestoreSettingsService, coinSettingsService: CoinSettingsService) {
        self.coinPlatformsService = coinPlatformsService
        self.restoreSettingsService = restoreSettingsService
        self.coinSettingsService = coinSettingsService

        subscribe(disposeBag, coinPlatformsService.approvePlatformsObservable) { [weak self] coinWithPlatforms in
            self?.handleApproveCoinPlatforms(coin: coinWithPlatforms.coin, platforms: coinWithPlatforms.platforms)
        }
        subscribe(disposeBag, coinPlatformsService.rejectApprovePlatformsObservable) { [weak self] fullCoin in
            self?.handleRejectApprovePlatformSettings(fullCoin: fullCoin)
        }
        subscribe(disposeBag, restoreSettingsService.approveSettingsObservable) { [weak self] coinWithSettings in
            self?.handleApproveRestoreSettings(platformCoin: coinWithSettings.platformCoin, settings: coinWithSettings.settings)
        }
        subscribe(disposeBag, restoreSettingsService.rejectApproveSettingsObservable) { [weak self] platformCoin in
            self?.handleRejectApproveRestoreSettings(platformCoin: platformCoin)
        }
        subscribe(disposeBag, coinSettingsService.approveSettingsObservable) { [weak self] coinWithSettings in
            self?.handleApproveCoinSettings(platformCoin: coinWithSettings.platformCoin, settingsArray: coinWithSettings.settingsArray)
        }
        subscribe(disposeBag, coinSettingsService.rejectApproveSettingsObservable) { [weak self] platformCoin in
            self?.handleRejectApproveCoinSettings(platformCoin: platformCoin)
        }
    }

    private func handleApproveRestoreSettings(platformCoin: PlatformCoin, settings: RestoreSettings = [:]) {
        enableCoinRelay.accept(([ConfiguredPlatformCoin(platformCoin: platformCoin)], settings))
    }

    private func handleRejectApproveRestoreSettings(platformCoin: PlatformCoin) {
        cancelEnableCoinRelay.accept(platformCoin.fullCoin)
    }

    private func handleApproveCoinSettings(platformCoin: PlatformCoin, settingsArray: [CoinSettings] = []) {
        let configuredPlatformCoins = settingsArray.map { ConfiguredPlatformCoin(platformCoin: platformCoin, coinSettings: $0) }
        enableCoinRelay.accept((configuredPlatformCoins, [:]))
    }

    private func handleRejectApproveCoinSettings(platformCoin: PlatformCoin) {
        cancelEnableCoinRelay.accept(platformCoin.fullCoin)
    }

    private func handleApproveCoinPlatforms(coin: Coin, platforms: [Platform]) {
        let configuredPlatformCoins = platforms.map { ConfiguredPlatformCoin(platformCoin: PlatformCoin(coin: coin, platform: $0)) }
        enableCoinRelay.accept((configuredPlatformCoins, [:]))
    }

    private func handleRejectApprovePlatformSettings(fullCoin: FullCoin) {
        cancelEnableCoinRelay.accept(fullCoin)
    }

}

extension EnableCoinService {

    var enableCoinObservable: Observable<([ConfiguredPlatformCoin], RestoreSettings)> {
        enableCoinRelay.asObservable()
    }

    var cancelEnableCoinObservable: Observable<FullCoin> {
        cancelEnableCoinRelay.asObservable()
    }

    func enable(fullCoin: FullCoin, account: Account? = nil) {
        let supportedPlatforms = fullCoin.supportedPlatforms

        if supportedPlatforms.count == 1 {
            let platformCoin = PlatformCoin(coin: fullCoin.coin, platform: supportedPlatforms[0])

            if !platformCoin.coinType.restoreSettingTypes.isEmpty {
                restoreSettingsService.approveSettings(platformCoin: platformCoin, account: account)
            } else if !platformCoin.coinType.coinSettingTypes.isEmpty {
                coinSettingsService.approveSettings(platformCoin: platformCoin, settingsArray: platformCoin.coinType.defaultSettingsArray)
            } else {
                enableCoinRelay.accept(([ConfiguredPlatformCoin(platformCoin: platformCoin)], [:]))
            }
        } else {
            coinPlatformsService.approvePlatforms(fullCoin: fullCoin)
        }
    }

    func configure(fullCoin: FullCoin, configuredPlatformCoins: [ConfiguredPlatformCoin]) {
        let supportedPlatforms = fullCoin.supportedPlatforms

        if supportedPlatforms.count == 1 {
            let platform = supportedPlatforms[0]

            if !platform.coinType.coinSettingTypes.isEmpty {
                let settingsArray = configuredPlatformCoins.map { $0.coinSettings }
                coinSettingsService.approveSettings(platformCoin: PlatformCoin(coin: fullCoin.coin, platform: platform), settingsArray: settingsArray)
            }
        } else {
            let currentPlatforms = configuredPlatformCoins.map { $0.platformCoin.platform }
            coinPlatformsService.approvePlatforms(fullCoin: fullCoin, currentPlatforms: currentPlatforms)
        }
    }

    func save(restoreSettings: RestoreSettings, account: Account, coinType: CoinType) {
        restoreSettingsService.save(settings: restoreSettings, account: account, coinType: coinType)
    }

}

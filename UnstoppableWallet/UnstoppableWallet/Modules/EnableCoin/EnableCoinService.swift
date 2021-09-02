import RxSwift
import RxRelay
import MarketKit

class EnableCoinService {
    private let coinPlatformsService: CoinPlatformsService
    private let restoreSettingsService: RestoreSettingsService
    private let coinSettingsService: CoinSettingsService
    private let disposeBag = DisposeBag()

    private let enableCoinRelay = PublishRelay<([ConfiguredPlatformCoin], RestoreSettings)>()
    private let cancelEnableCoinRelay = PublishRelay<Coin>()

    init(coinPlatformsService: CoinPlatformsService, restoreSettingsService: RestoreSettingsService, coinSettingsService: CoinSettingsService) {
        self.coinPlatformsService = coinPlatformsService
        self.restoreSettingsService = restoreSettingsService
        self.coinSettingsService = coinSettingsService

        subscribe(disposeBag, coinPlatformsService.approvePlatformsObservable) { [weak self] coinWithPlatforms in
            self?.handleApproveCoinPlatforms(coin: coinWithPlatforms.coin, platforms: coinWithPlatforms.platforms)
        }
        subscribe(disposeBag, coinPlatformsService.rejectApprovePlatformsObservable) { [weak self] coin in
            self?.handleRejectApprovePlatformSettings(coin: coin)
        }
        subscribe(disposeBag, restoreSettingsService.approveSettingsObservable) { [weak self] coinWithSettings in
            self?.handleApproveRestoreSettings(platformCoin: coinWithSettings.platformCoin, settings: coinWithSettings.settings)
        }
        subscribe(disposeBag, restoreSettingsService.rejectApproveSettingsObservable) { [weak self] coin in
            self?.handleRejectApproveRestoreSettings(coin: coin)
        }
        subscribe(disposeBag, coinSettingsService.approveSettingsObservable) { [weak self] coinWithSettings in
            self?.handleApproveCoinSettings(platformCoin: coinWithSettings.platformCoin, settingsArray: coinWithSettings.settingsArray)
        }
        subscribe(disposeBag, coinSettingsService.rejectApproveSettingsObservable) { [weak self] coin in
            self?.handleRejectApproveCoinSettings(coin: coin)
        }
    }

    private func handleApproveRestoreSettings(platformCoin: PlatformCoin, settings: RestoreSettings = [:]) {
        enableCoinRelay.accept(([ConfiguredPlatformCoin(platformCoin: platformCoin)], settings))
    }

    private func handleRejectApproveRestoreSettings(coin: Coin) {
        cancelEnableCoinRelay.accept(coin)
    }

    private func handleApproveCoinSettings(platformCoin: PlatformCoin, settingsArray: [CoinSettings] = []) {
        let configuredPlatformCoins = settingsArray.map { ConfiguredPlatformCoin(platformCoin: platformCoin, settings: $0) }
        enableCoinRelay.accept((configuredPlatformCoins, [:]))
    }

    private func handleRejectApproveCoinSettings(coin: Coin) {
        cancelEnableCoinRelay.accept(coin)
    }

    private func handleApproveCoinPlatforms(coin: Coin, platforms: [Platform]) {
        let configuredPlatformCoins = platforms.map { ConfiguredPlatformCoin(platformCoin: PlatformCoin(coin: coin, platform: $0)) }
        enableCoinRelay.accept((configuredPlatformCoins, [:]))
    }

    private func handleRejectApprovePlatformSettings(coin: Coin) {
        cancelEnableCoinRelay.accept(coin)
    }

}

extension EnableCoinService {

    var enableCoinObservable: Observable<([ConfiguredPlatformCoin], RestoreSettings)> {
        enableCoinRelay.asObservable()
    }

    var cancelEnableCoinObservable: Observable<Coin> {
        cancelEnableCoinRelay.asObservable()
    }

    func enable(marketCoin: MarketCoin, account: Account? = nil) {
        if marketCoin.platforms.count == 1 {
            let platformCoin = PlatformCoin(coin: marketCoin.coin, platform: marketCoin.platforms[0])

            if !platformCoin.coinType.restoreSettingTypes.isEmpty {
                restoreSettingsService.approveSettings(platformCoin: platformCoin, account: account)
            } else if !platformCoin.coinType.coinSettingTypes.isEmpty {
                coinSettingsService.approveSettings(platformCoin: platformCoin, settingsArray: platformCoin.coinType.defaultSettingsArray)
            } else {
                enableCoinRelay.accept(([ConfiguredPlatformCoin(platformCoin: platformCoin)], [:]))
            }
        } else {
            coinPlatformsService.approvePlatforms(marketCoin: marketCoin)
        }
    }

    func configure(marketCoin: MarketCoin, configuredPlatformCoins: [ConfiguredPlatformCoin]) {
        if marketCoin.platforms.count == 1 {
            let platform = marketCoin.platforms[0]

            if !platform.coinType.coinSettingTypes.isEmpty {
                let settingsArray = configuredPlatformCoins.map { $0.settings }
                coinSettingsService.approveSettings(platformCoin: PlatformCoin(coin: marketCoin.coin, platform: platform), settingsArray: settingsArray)
            }
        } else {
            let currentPlatforms = configuredPlatformCoins.map { $0.platformCoin.platform }
            coinPlatformsService.approvePlatforms(marketCoin: marketCoin, currentPlatforms: currentPlatforms)
        }
    }

    func save(restoreSettings: RestoreSettings, account: Account, coinType: CoinType) {
        restoreSettingsService.save(settings: restoreSettings, account: account, coinType: coinType)
    }

}

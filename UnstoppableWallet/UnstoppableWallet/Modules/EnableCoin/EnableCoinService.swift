import RxSwift
import RxRelay
import MarketKit

class EnableCoinService {
    private let coinTokensService: CoinTokensService
    private let restoreSettingsService: RestoreSettingsService
    private let coinSettingsService: CoinSettingsService
    private let disposeBag = DisposeBag()

    private let enableCoinRelay = PublishRelay<([ConfiguredToken], RestoreSettings)>()
    private let disableCoinRelay = PublishRelay<Coin>()
    private let cancelEnableCoinRelay = PublishRelay<FullCoin>()

    init(coinTokensService: CoinTokensService, restoreSettingsService: RestoreSettingsService, coinSettingsService: CoinSettingsService) {
        self.coinTokensService = coinTokensService
        self.restoreSettingsService = restoreSettingsService
        self.coinSettingsService = coinSettingsService

        subscribe(disposeBag, coinTokensService.approveTokensObservable) { [weak self] coinWithTokens in
            self?.handleApproveCoinTokens(coin: coinWithTokens.coin, tokens: coinWithTokens.tokens)
        }
        subscribe(disposeBag, coinTokensService.rejectApproveTokensObservable) { [weak self] fullCoin in
            self?.handleRejectApproveTokenSettings(fullCoin: fullCoin)
        }
        subscribe(disposeBag, restoreSettingsService.approveSettingsObservable) { [weak self] tokenWithSettings in
            self?.handleApproveRestoreSettings(token: tokenWithSettings.token, settings: tokenWithSettings.settings)
        }
        subscribe(disposeBag, restoreSettingsService.rejectApproveSettingsObservable) { [weak self] token in
            self?.handleRejectApproveRestoreSettings(token: token)
        }
        subscribe(disposeBag, coinSettingsService.approveSettingsObservable) { [weak self] tokenWithSettings in
            self?.handleApproveCoinSettings(token: tokenWithSettings.token, settingsArray: tokenWithSettings.settingsArray)
        }
        subscribe(disposeBag, coinSettingsService.rejectApproveSettingsObservable) { [weak self] token in
            self?.handleRejectApproveCoinSettings(token: token)
        }
    }

    private func handleApproveRestoreSettings(token: Token, settings: RestoreSettings = [:]) {
        enableCoinRelay.accept(([ConfiguredToken(token: token)], settings))
    }

    private func handleRejectApproveRestoreSettings(token: Token) {
        cancelEnableCoinRelay.accept(token.fullCoin)
    }

    private func handleApproveCoinSettings(token: Token, settingsArray: [CoinSettings] = []) {
        if settingsArray.isEmpty {
            disableCoinRelay.accept(token.coin)
        } else {
            let configuredTokens = settingsArray.map { ConfiguredToken(token: token, coinSettings: $0) }
            enableCoinRelay.accept((configuredTokens, [:]))
        }
    }

    private func handleRejectApproveCoinSettings(token: Token) {
        cancelEnableCoinRelay.accept(token.fullCoin)
    }

    private func handleApproveCoinTokens(coin: Coin, tokens: [Token]) {
        if tokens.isEmpty {
            disableCoinRelay.accept(coin)
        } else {
            let configuredTokens = tokens.map { ConfiguredToken(token: $0) }
            enableCoinRelay.accept((configuredTokens, [:]))
        }
    }

    private func handleRejectApproveTokenSettings(fullCoin: FullCoin) {
        cancelEnableCoinRelay.accept(fullCoin)
    }

}

extension EnableCoinService {

    var enableCoinObservable: Observable<([ConfiguredToken], RestoreSettings)> {
        enableCoinRelay.asObservable()
    }

    var disableCoinObservable: Observable<Coin> {
        disableCoinRelay.asObservable()
    }

    var cancelEnableCoinObservable: Observable<FullCoin> {
        cancelEnableCoinRelay.asObservable()
    }

    func enable(fullCoin: FullCoin, accountType: AccountType, account: Account? = nil) {
        let supportedTokens = fullCoin.supportedTokens

        if supportedTokens.count == 1 {
            let token = supportedTokens[0]

            if !token.blockchainType.restoreSettingTypes.isEmpty {
                restoreSettingsService.approveSettings(token: token, account: account)
            } else if token.blockchainType.coinSettingType != nil {
                coinSettingsService.approveSettings(token: token, accountType: accountType, settingsArray: token.blockchainType.defaultSettingsArray(accountType: accountType))
            } else if token.type != .native {
                coinTokensService.approveTokens(fullCoin: fullCoin, currentTokens: supportedTokens)
            } else {
                enableCoinRelay.accept(([ConfiguredToken(token: token)], [:]))
            }
        } else {
            coinTokensService.approveTokens(fullCoin: fullCoin, currentTokens: supportedTokens.isEmpty ? [] : [supportedTokens.sorted[0]])
        }
    }

    func configure(fullCoin: FullCoin, accountType: AccountType, configuredTokens: [ConfiguredToken]) {
        let supportedTokens = fullCoin.supportedTokens

        if supportedTokens.count == 1 {
            let token = supportedTokens[0]

            if token.blockchainType.coinSettingType != nil {
                let settingsArray = configuredTokens.map { $0.coinSettings }
                coinSettingsService.approveSettings(token: token, accountType: accountType, settingsArray: settingsArray, allowEmpty: true)
                return
            }
        }

        let currentTokens = configuredTokens.map { $0.token }
        coinTokensService.approveTokens(fullCoin: fullCoin, currentTokens: currentTokens, allowEmpty: true)
    }

    func save(restoreSettings: RestoreSettings, account: Account, blockchainType: BlockchainType) {
        restoreSettingsService.save(settings: restoreSettings, account: account, blockchainType: blockchainType)
    }

}

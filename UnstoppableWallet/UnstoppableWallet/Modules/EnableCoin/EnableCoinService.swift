import RxSwift
import RxRelay
import MarketKit

class EnableCoinService {
    private let coinTokensService: CoinTokensService
    private let coinSettingsService: CoinSettingsService
    private let disposeBag = DisposeBag()

    private let enableCoinRelay = PublishRelay<[ConfiguredToken]>()
    private let disableCoinRelay = PublishRelay<Coin>()
    private let cancelEnableCoinRelay = PublishRelay<FullCoin>()

    init(coinTokensService: CoinTokensService, coinSettingsService: CoinSettingsService) {
        self.coinTokensService = coinTokensService
        self.coinSettingsService = coinSettingsService

        subscribe(disposeBag, coinTokensService.approveTokensObservable) { [weak self] coinWithTokens in
            self?.handleApproveCoinTokens(coin: coinWithTokens.coin, tokens: coinWithTokens.tokens)
        }
        subscribe(disposeBag, coinTokensService.rejectApproveTokensObservable) { [weak self] fullCoin in
            self?.handleRejectApproveTokenSettings(fullCoin: fullCoin)
        }
        subscribe(disposeBag, coinSettingsService.approveSettingsObservable) { [weak self] tokenWithSettings in
            self?.handleApproveCoinSettings(token: tokenWithSettings.token, settingsArray: tokenWithSettings.settingsArray)
        }
        subscribe(disposeBag, coinSettingsService.rejectApproveSettingsObservable) { [weak self] token in
            self?.handleRejectApproveCoinSettings(token: token)
        }
    }

    private func handleApproveCoinSettings(token: Token, settingsArray: [CoinSettings] = []) {
        if settingsArray.isEmpty {
            disableCoinRelay.accept(token.coin)
        } else {
            let configuredTokens = settingsArray.map { ConfiguredToken(token: token, coinSettings: $0) }
            enableCoinRelay.accept(configuredTokens)
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
            enableCoinRelay.accept(configuredTokens)
        }
    }

    private func handleRejectApproveTokenSettings(fullCoin: FullCoin) {
        cancelEnableCoinRelay.accept(fullCoin)
    }

}

extension EnableCoinService {

    var enableCoinObservable: Observable<[ConfiguredToken]> {
        enableCoinRelay.asObservable()
    }

    var disableCoinObservable: Observable<Coin> {
        disableCoinRelay.asObservable()
    }

    var cancelEnableCoinObservable: Observable<FullCoin> {
        cancelEnableCoinRelay.asObservable()
    }

    func enable(fullCoin: FullCoin, accountType: AccountType, accountOrigin: AccountOrigin) {
        let supportedTokens = fullCoin.supportedTokens

        if supportedTokens.count == 1 {
            let token = supportedTokens[0]

            if !token.blockchainType.coinSettingTypes(accountOrigin: accountOrigin).isEmpty {
                coinSettingsService.approveSettings(
                        token: token,
                        accountType: accountType,
                        accountOrigin: accountOrigin,
                        settingsArray: token.blockchainType.defaultSettingsArray(accountType: accountType, accountOrigin: accountOrigin),
                        initial: true
                )
            } else if token.type != .native {
                coinTokensService.approveTokens(fullCoin: fullCoin, currentTokens: supportedTokens)
            } else {
                enableCoinRelay.accept([ConfiguredToken(token: token)])
            }
        } else {
            coinTokensService.approveTokens(fullCoin: fullCoin, currentTokens: supportedTokens.isEmpty ? [] : [supportedTokens.sorted[0]])
        }
    }

    func configure(fullCoin: FullCoin, accountType: AccountType, accountOrigin: AccountOrigin, configuredTokens: [ConfiguredToken]) {
        let supportedTokens = fullCoin.supportedTokens

        if supportedTokens.count == 1 {
            let token = supportedTokens[0]

            if !token.blockchainType.coinSettingTypes(accountOrigin: accountOrigin).isEmpty {
                let settingsArray = configuredTokens.map { $0.coinSettings }
                coinSettingsService.approveSettings(
                        token: token,
                        accountType: accountType,
                        accountOrigin: accountOrigin,
                        settingsArray: settingsArray,
                        initial: false
                )
                return
            }
        }

        let currentTokens = configuredTokens.map { $0.token }
        coinTokensService.approveTokens(fullCoin: fullCoin, currentTokens: currentTokens, allowEmpty: true)
    }

}

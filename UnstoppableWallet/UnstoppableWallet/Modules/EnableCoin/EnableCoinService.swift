import RxSwift
import RxRelay
import MarketKit

class EnableCoinService {
    private let coinTokensService: CoinTokensService
    private let restoreSettingsService: RestoreSettingsService
    private let disposeBag = DisposeBag()

    private let enableCoinRelay = PublishRelay<([Token], RestoreSettings)>()
    private let disableCoinRelay = PublishRelay<Coin>()
    private let cancelEnableCoinRelay = PublishRelay<Coin>()

    init(coinTokensService: CoinTokensService, restoreSettingsService: RestoreSettingsService) {
        self.coinTokensService = coinTokensService
        self.restoreSettingsService = restoreSettingsService

        subscribe(disposeBag, coinTokensService.approveTokensObservable) { [weak self] coinWithTokens in
            self?.handleApproveCoinTokens(coin: coinWithTokens.coin, tokens: coinWithTokens.tokens)
        }
        subscribe(disposeBag, coinTokensService.rejectApproveTokensObservable) { [weak self] coin in
            self?.handleRejectApproveTokenSettings(coin: coin)
        }
        subscribe(disposeBag, restoreSettingsService.approveSettingsObservable) { [weak self] tokenWithSettings in
            self?.handleApproveRestoreSettings(token: tokenWithSettings.token, settings: tokenWithSettings.settings)
        }
        subscribe(disposeBag, restoreSettingsService.rejectApproveSettingsObservable) { [weak self] token in
            self?.handleRejectApproveRestoreSettings(token: token)
        }
    }

    private func handleApproveRestoreSettings(token: Token, settings: RestoreSettings = [:]) {
        enableCoinRelay.accept(([token], settings))
    }

    private func handleRejectApproveRestoreSettings(token: Token) {
        cancelEnableCoinRelay.accept(token.coin)
    }

    private func handleApproveCoinTokens(coin: Coin, tokens: [Token]) {
        if tokens.isEmpty {
            disableCoinRelay.accept(coin)
        } else {
            enableCoinRelay.accept((tokens, [:]))
        }
    }

    private func handleRejectApproveTokenSettings(coin: Coin) {
        cancelEnableCoinRelay.accept(coin)
    }

}

extension EnableCoinService {

    var enableCoinObservable: Observable<([Token], RestoreSettings)> {
        enableCoinRelay.asObservable()
    }

    var disableCoinObservable: Observable<Coin> {
        disableCoinRelay.asObservable()
    }

    var cancelEnableCoinObservable: Observable<Coin> {
        cancelEnableCoinRelay.asObservable()
    }

    func enable(fullCoin: FullCoin, accountType: AccountType, account: Account? = nil) {
        let eligibleTokens = fullCoin.eligibleTokens(accountType: accountType)

        if eligibleTokens.count == 1 {
            let token = eligibleTokens[0]

            if !token.blockchainType.restoreSettingTypes.isEmpty {
                restoreSettingsService.approveSettings(token: token, account: account)
            } else if token.type != .native {
                coinTokensService.approveTokens(coin: fullCoin.coin, eligibleTokens: eligibleTokens, currentTokens: eligibleTokens)
            } else {
                enableCoinRelay.accept(([token], [:]))
            }
        } else {
            coinTokensService.approveTokens(coin: fullCoin.coin, eligibleTokens: eligibleTokens, currentTokens: eligibleTokens.isEmpty ? [] : [eligibleTokens.sorted()[0]])
        }
    }

    func configure(fullCoin: FullCoin, accountType: AccountType, tokens: [Token]) {
        let eligibleTokens = fullCoin.eligibleTokens(accountType: accountType)
        coinTokensService.approveTokens(coin: fullCoin.coin, eligibleTokens: eligibleTokens, currentTokens: tokens, allowEmpty: true)
    }

    func save(restoreSettings: RestoreSettings, account: Account, blockchainType: BlockchainType) {
        restoreSettingsService.save(settings: restoreSettings, account: account, blockchainType: blockchainType)
    }

}

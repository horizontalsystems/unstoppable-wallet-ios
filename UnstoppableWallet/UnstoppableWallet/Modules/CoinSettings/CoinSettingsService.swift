import RxSwift
import RxRelay
import MarketKit

class CoinSettingsService {
    private let isRestore: Bool

    private let approveSettingsRelay = PublishRelay<TokenWithSettings>()
    private let rejectApproveSettingsRelay = PublishRelay<Token>()
    private let requestRelay = PublishRelay<Request>()

    init(isRestore: Bool) {
        self.isRestore = isRestore
    }

}

extension CoinSettingsService {

    var approveSettingsObservable: Observable<TokenWithSettings> {
        approveSettingsRelay.asObservable()
    }

    var rejectApproveSettingsObservable: Observable<Token> {
        rejectApproveSettingsRelay.asObservable()
    }

    var requestObservable: Observable<Request> {
        requestRelay.asObservable()
    }

    func approveSettings(token: Token, accountType: AccountType, accountOrigin: AccountOrigin, settingsArray: [CoinSettings], initial: Bool) {
        let blockchainType = token.blockchainType

        if BlockchainType.btcTypes.contains(blockchainType) {
            let request = Request(
                    token: token,
                    type: .btc,
                    blockchain: token.blockchain,
                    accountType: accountType,
                    accountOrigin: accountOrigin,
                    coinSettingsArray: settingsArray,
                    initial: initial,
                    isRestore: isRestore
            )

            requestRelay.accept(request)
            return
        }

        approveSettingsRelay.accept(TokenWithSettings(token: token))
    }

    func approve(coinSettingsArray: [CoinSettings], token: Token) {
        let tokenWithSettings = TokenWithSettings(token: token, settingsArray: coinSettingsArray)
        approveSettingsRelay.accept(tokenWithSettings)
    }

    func cancel(token: Token) {
        rejectApproveSettingsRelay.accept(token)
    }

}

extension CoinSettingsService {

    struct TokenWithSettings {
        let token: Token
        let settingsArray: [CoinSettings]

        init(token: Token, settingsArray: [CoinSettings] = []) {
            self.token = token
            self.settingsArray = settingsArray
        }
    }

    struct Request {
        let token: Token
        let type: RequestType
        let blockchain: Blockchain
        let accountType: AccountType
        let accountOrigin: AccountOrigin
        let coinSettingsArray: [CoinSettings]
        let initial: Bool
        let isRestore: Bool
    }

    enum RequestType {
        case btc
        case zcash
    }

}

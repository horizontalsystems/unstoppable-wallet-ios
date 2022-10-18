import RxSwift
import RxRelay
import MarketKit

class CoinSettingsService {
    private let approveSettingsRelay = PublishRelay<TokenWithSettings>()
    private let rejectApproveSettingsRelay = PublishRelay<Token>()

    private let requestRelay = PublishRelay<Request>()
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

    func approveSettings(token: Token, accountType: AccountType, settingsArray: [CoinSettings], allowEmpty: Bool = false) {
        let blockchainType = token.blockchainType

        if blockchainType.coinSettingType == .derivation {
            let currentDerivations = settingsArray.compactMap { $0[.derivation].flatMap { MnemonicDerivation(rawValue: $0) } }

            let request = Request(
                    token: token,
                    type: .derivation(allDerivations: accountType.supportedDerivations, current: currentDerivations),
                    allowEmpty: allowEmpty
            )

            requestRelay.accept(request)
            return
        }

        if blockchainType.coinSettingType == .bitcoinCashCoinType {
            let currentTypes = settingsArray.compactMap { $0[.bitcoinCashCoinType].flatMap { BitcoinCashCoinType(rawValue: $0) } }

            let request = Request(
                    token: token,
                    type: .bitcoinCashCoinType(allTypes: BitcoinCashCoinType.allCases, current: currentTypes),
                    allowEmpty: allowEmpty
            )

            requestRelay.accept(request)
            return
        }

        approveSettingsRelay.accept(TokenWithSettings(token: token))
    }

    func select(derivations: [MnemonicDerivation], token: Token) {
        let settingsArray: [CoinSettings] = derivations.map { [.derivation: $0.rawValue] }
        let tokenWithSettings = TokenWithSettings(token: token, settingsArray: settingsArray)
        approveSettingsRelay.accept(tokenWithSettings)
    }

    func select(bitcoinCashCoinTypes: [BitcoinCashCoinType], token: Token) {
        let settingsArray: [CoinSettings] = bitcoinCashCoinTypes.map { [.bitcoinCashCoinType: $0.rawValue] }
        let tokenWithSettings = TokenWithSettings(token: token, settingsArray: settingsArray)
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
        let allowEmpty: Bool
    }

    enum RequestType {
        case derivation(allDerivations: [MnemonicDerivation], current: [MnemonicDerivation])
        case bitcoinCashCoinType(allTypes: [BitcoinCashCoinType], current: [BitcoinCashCoinType])
    }

}

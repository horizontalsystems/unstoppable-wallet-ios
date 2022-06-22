import RxSwift
import RxRelay
import MarketKit

class RestoreSettingsService {
    private let manager: RestoreSettingsManager

    private let approveSettingsRelay = PublishRelay<TokenWithSettings>()
    private let rejectApproveSettingsRelay = PublishRelay<Token>()

    private let requestRelay = PublishRelay<Request>()

    init(manager: RestoreSettingsManager) {
        self.manager = manager
    }

}

extension RestoreSettingsService {

    var approveSettingsObservable: Observable<TokenWithSettings> {
        approveSettingsRelay.asObservable()
    }

    var rejectApproveSettingsObservable: Observable<Token> {
        rejectApproveSettingsRelay.asObservable()
    }

    var requestObservable: Observable<Request> {
        requestRelay.asObservable()
    }

    func approveSettings(token: Token, account: Account? = nil) {
        let blockchainType = token.blockchainType

        if let account = account, case .created = account.origin {
            var settings = RestoreSettings()

            for type in blockchainType.restoreSettingTypes {
                settings[type] = type.createdAccountValue(blockchainType: blockchainType)
            }

            approveSettingsRelay.accept(TokenWithSettings(token: token, settings: settings))
            return
        }

        let existingSettings = account.map { manager.settings(account: $0, blockchainType: blockchainType) } ?? [:]

        if blockchainType.restoreSettingTypes.contains(.birthdayHeight) && existingSettings[.birthdayHeight] == nil {
            let request = Request(
                    token: token,
                    type: .birthdayHeight
            )

            requestRelay.accept(request)
            return
        }

        approveSettingsRelay.accept(TokenWithSettings(token: token, settings: [:]))
    }

    func save(settings: RestoreSettings, account: Account, blockchainType: BlockchainType) {
        manager.save(settings: settings, account: account, blockchainType: blockchainType)
    }

    func enter(birthdayHeight: Int?, token: Token) {
        var settings = RestoreSettings()
        if let birthdayHeight = birthdayHeight?.description ?? RestoreSettingType.birthdayHeight.createdAccountValue(blockchainType: token.blockchainType) {
            settings[.birthdayHeight] = String(birthdayHeight)
        }

        let tokenWithSettings = TokenWithSettings(token: token, settings: settings)
        approveSettingsRelay.accept(tokenWithSettings)
    }

    func cancel(token: Token) {
        rejectApproveSettingsRelay.accept(token)
    }

}

extension RestoreSettingsService {

    struct TokenWithSettings {
        let token: Token
        let settings: RestoreSettings
    }

    struct Request {
        let token: Token
        let type: RequestType
    }

    enum RequestType {
        case birthdayHeight
    }

}

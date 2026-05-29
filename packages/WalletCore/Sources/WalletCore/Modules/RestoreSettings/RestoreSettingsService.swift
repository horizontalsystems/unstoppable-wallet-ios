import Combine
import MarketKit

class RestoreSettingsService {
    private let manager: RestoreSettingsManager

    private let approveSettingsSubject = PassthroughSubject<TokenWithSettings, Never>()
    private let rejectApproveSettingsSubject = PassthroughSubject<Token, Never>()
    private let requestSubject = PassthroughSubject<Request, Never>()

    init(manager: RestoreSettingsManager) {
        self.manager = manager
    }
}

extension RestoreSettingsService {
    var approveSettingsPublisher: AnyPublisher<TokenWithSettings, Never> {
        approveSettingsSubject.eraseToAnyPublisher()
    }

    var rejectApproveSettingsPublisher: AnyPublisher<Token, Never> {
        rejectApproveSettingsSubject.eraseToAnyPublisher()
    }

    var requestPublisher: AnyPublisher<Request, Never> {
        requestSubject.eraseToAnyPublisher()
    }

    func approveSettings(token: Token, account: Account? = nil) {
        let blockchainType = token.blockchainType

        if let account, case .created = account.origin {
            var settings = RestoreSettings()

            for type in blockchainType.restoreSettingTypes {
                settings[type] = type.createdAccountValue(blockchainType: blockchainType)
            }

            approveSettingsSubject.send(TokenWithSettings(token: token, settings: settings))
            return
        }

        let existingSettings = account.map { manager.settings(accountId: $0.id, blockchainType: blockchainType) } ?? [:]

        if blockchainType.restoreSettingTypes.contains(.birthdayHeight), existingSettings[.birthdayHeight] == nil {
            let request = Request(
                token: token,
                type: .birthdayHeight
            )

            requestSubject.send(request)
            return
        }

        approveSettingsSubject.send(TokenWithSettings(token: token, settings: [:]))
    }

    func save(settings: RestoreSettings, account: Account, blockchainType: BlockchainType) {
        manager.save(settings: settings, account: account, blockchainType: blockchainType)
    }

    @discardableResult func enter(birthdayHeight: Int?, token: Token) -> TokenWithSettings {
        var settings = RestoreSettings()
        if let birthdayHeight = birthdayHeight?.description ?? RestoreSettingType.birthdayHeight.createdAccountValue(blockchainType: token.blockchainType) {
            settings[.birthdayHeight] = String(birthdayHeight)
        }

        let tokenWithSettings = TokenWithSettings(token: token, settings: settings)
        approveSettingsSubject.send(tokenWithSettings)

        return tokenWithSettings
    }

    func cancel(token: Token) {
        rejectApproveSettingsSubject.send(token)
    }

    func settings(accountId: String, blockchainType: BlockchainType) -> RestoreSettings {
        manager.settings(accountId: accountId, blockchainType: blockchainType)
    }

    func set(birthdayHeight: String, account: Account, blokcchainType: BlockchainType) {
        var settings = RestoreSettings()
        settings[.birthdayHeight] = birthdayHeight
        save(settings: settings, account: account, blockchainType: blokcchainType)
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

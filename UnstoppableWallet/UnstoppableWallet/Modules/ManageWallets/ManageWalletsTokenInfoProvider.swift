import Foundation
import MarketKit

class ManageWalletsTokenInfoProvider {
    private let restoreSettingsService: RestoreSettingsService

    init(restoreSettingsService: RestoreSettingsService) {
        self.restoreSettingsService = restoreSettingsService
    }

    private func derivationInfo(token: Token) -> InfoItem? {
        switch token.type {
        case .derived:
            return InfoItem(token: token, type: .derivation)
        case .addressType:
            return InfoItem(token: token, type: .bitcoinCashCoinType)
        default:
            return nil
        }
    }

    private func birthdayHeightInfo(token: Token, accountId: String) -> InfoItem? {
        let blockchainType = token.blockchainType

        for settingType in blockchainType.restoreSettingTypes {
            switch settingType {
            case .birthdayHeight:
                let settings = restoreSettingsService.settings(accountId: accountId, blockchainType: blockchainType)
                if let height = settings.birthdayHeight {
                    return InfoItem(token: token, type: .birthdayHeight(height: height))
                }
            }
        }

        return nil
    }

    private func contractInfo(token: Token) -> InfoItem? {
        switch token.type {
        case let .eip20(address):
            return InfoItem(
                token: token,
                type: .contractAddress(value: address, explorerUrl: token.blockchain.explorerUrl(reference: address))
            )
        case let .jetton(address):
            return InfoItem(
                token: token,
                type: .contractAddress(value: address, explorerUrl: token.blockchain.explorerUrl(reference: address))
            )
        case let .stellar(code, issuer):
            let assetId = [code, issuer].joined(separator: "-")
            return InfoItem(
                token: token,
                type: .contractAddress(value: assetId, explorerUrl: token.blockchain.explorerUrl(reference: assetId))
            )
        default:
            return nil
        }
    }
}

extension ManageWalletsTokenInfoProvider {
    func hasInfo(token: Token, isEnabled: Bool) -> Bool {
        switch token.type {
        case .derived, .addressType:
            return true
        default:
            break
        }

        if isEnabled && !token.blockchainType.restoreSettingTypes.isEmpty {
            return true
        }

        switch token.type {
        case .eip20, .jetton, .stellar:
            return true
        default:
            return false
        }
    }

    func infoItem(token: Token, accountId: String) -> InfoItem? {
        if let info = derivationInfo(token: token) {
            return info
        }

        if let info = birthdayHeightInfo(token: token, accountId: accountId) {
            return info
        }

        return contractInfo(token: token)
    }
}

extension ManageWalletsTokenInfoProvider {
    struct InfoItem {
        let token: Token
        let type: InfoType
    }

    enum InfoType: Equatable {
        case derivation
        case bitcoinCashCoinType
        case birthdayHeight(height: Int)
        case contractAddress(value: String, explorerUrl: String?)
    }
}

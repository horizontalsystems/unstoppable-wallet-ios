import EvmKit
import Foundation
import MarketKit
import RxRelay
import RxSwift

class ManageWalletsService {
    private var queue = DispatchQueue(label: "\(AppConfig.label).manage-wallets-service.tokens", qos: .userInitiated)

    private let account: Account
    private let marketKit: MarketKit.Kit
    private let walletManager: WalletManager
    private let restoreSettingsService: RestoreSettingsService
    private let disposeBag = DisposeBag()

    private var tokens = [Token]()
    private var wallets = Set<Wallet>()
    private var filter: String = ""

    private let itemsRelay = PublishRelay<[Item]>()
    private let cancelEnableRelay = PublishRelay<Int>()

    var items: [Item] = [] {
        didSet {
            itemsRelay.accept(items)
        }
    }

    init?(marketKit: MarketKit.Kit, walletManager: WalletManager, accountManager: AccountManager, restoreSettingsService: RestoreSettingsService) {
        guard let account = accountManager.activeAccount else {
            return nil
        }

        self.account = account
        self.marketKit = marketKit
        self.walletManager = walletManager
        self.restoreSettingsService = restoreSettingsService

        subscribe(disposeBag, walletManager.activeWalletDataUpdatedObservable) { [weak self] walletData in
            self?.handleUpdated(wallets: walletData.wallets)
        }
        subscribe(disposeBag, restoreSettingsService.approveSettingsObservable) { [weak self] tokenWithSettings in
            self?.handleApproveRestoreSettings(token: tokenWithSettings.token, settings: tokenWithSettings.settings)
        }
        subscribe(disposeBag, restoreSettingsService.rejectApproveSettingsObservable) { [weak self] token in
            self?.handleRejectApproveRestoreSettings(token: token)
        }

        sync(wallets: walletManager.activeWallets)
        syncTokens()
    }

    private func handleApproveRestoreSettings(token: Token, settings: RestoreSettings = [:]) {
        if !settings.isEmpty {
            restoreSettingsService.save(settings: settings, account: account, blockchainType: token.blockchainType)
        }

        save(token: token)
    }

    private func handleRejectApproveRestoreSettings(token: Token) {
        guard let index = tokens.firstIndex(where: { $0 == token }) else {
            return
        }

        cancelEnableRelay.accept(index)
    }

    private func fetchTokens() -> [Token] {
        do {
            if filter.trimmingCharacters(in: .whitespaces).isEmpty {
                let tokenQueries: [TokenQuery]
                if case .hdExtendedKey = account.type {
                    tokenQueries = BtcBlockchainManager.blockchainTypes.map(\.nativeTokenQueries).flatMap { $0 }
                } else {
                    tokenQueries = BlockchainType.supported.map(\.defaultTokenQuery)
                }

                let tokens = try marketKit.tokens(queries: tokenQueries)
                let featuredTokens = tokens.filter { account.type.supports(token: $0) }
                let enabledTokens = wallets.map(\.token)

                return (enabledTokens + featuredTokens).removeDuplicates()
            } else if let ethAddress = try? EvmKit.Address(hex: filter) {
                let address = ethAddress.hex
                let tokens = try marketKit.tokens(reference: address)

                return tokens.filter { account.type.supports(token: $0) }
            } else {
                let allFullCoins = try marketKit.fullCoins(filter: filter, limit: 100)
                let tokens = allFullCoins.map(\.tokens).flatMap { $0 }

                return tokens.filter { account.type.supports(token: $0) }
            }
        } catch {
            return []
        }
    }

    private func syncTokens(force: Bool = true) {
        queue.async { [weak self] in
            guard let self else { return }

            var newTokens = fetchTokens()

            if force || newTokens.count > tokens.count {
                sort(tokens: &newTokens)

                tokens = newTokens
                syncState()
            }
        }
    }

    private func isEnabled(token: Token) -> Bool {
        wallets.contains { $0.token == token }
    }

    private func sort(tokens: inout [Token]) {
        tokens.sort { lhsToken, rhsToken in
            let lhsEnabled = isEnabled(token: lhsToken)
            let rhsEnabled = isEnabled(token: rhsToken)

            if lhsEnabled != rhsEnabled {
                return lhsEnabled
            }

            if !filter.isEmpty {
                let filter = filter.lowercased()

                let lhsExactCode = lhsToken.coin.code.lowercased() == filter
                let rhsExactCode = rhsToken.coin.code.lowercased() == filter

                if lhsExactCode != rhsExactCode {
                    return lhsExactCode
                }

                let lhsStartsWithCode = lhsToken.coin.code.lowercased().starts(with: filter)
                let rhsStartsWithCode = rhsToken.coin.code.lowercased().starts(with: filter)

                if lhsStartsWithCode != rhsStartsWithCode {
                    return lhsStartsWithCode
                }

                let lhsStartsWithName = lhsToken.coin.name.lowercased().starts(with: filter)
                let rhsStartsWithName = rhsToken.coin.name.lowercased().starts(with: filter)

                if lhsStartsWithName != rhsStartsWithName {
                    return lhsStartsWithName
                }
            }
            if lhsToken.blockchainType.order != rhsToken.blockchainType.order {
                return lhsToken.blockchainType.order < rhsToken.blockchainType.order
            }
            return lhsToken.badge ?? "" < rhsToken.badge ?? ""
        }
    }

    private func sync(wallets: [Wallet]) {
        queue.async { [weak self] in
            guard let self else { return }

            self.wallets = Set(wallets)
        }
    }

    private func hasInfo(token: Token, enabled: Bool) -> Bool {
        switch token.type {
        case .derived, .addressType: return true
        default: ()
        }

        if !token.blockchainType.restoreSettingTypes.isEmpty, enabled {
            return true
        }

        switch token.type {
        case .eip20, .jetton, .stellar: return true
        default: return false
        }
    }

    private func item(token: Token) -> Item {
        let enabled = isEnabled(token: token)

        return Item(
            token: token,
            enabled: enabled,
            hasInfo: hasInfo(token: token, enabled: enabled)
        )
    }

    private func syncState() {
        items = tokens.map { item(token: $0) }
    }

    private func handleUpdated(wallets: [Wallet]) {
        sync(wallets: wallets)

        syncTokens(force: false)
    }

    private func save(token: Token) {
        let wallet = Wallet(token: token, account: account)
        walletManager.save(wallets: [wallet])
    }
}

extension ManageWalletsService {
    var itemsObservable: Observable<[Item]> {
        itemsRelay.asObservable()
    }

    var cancelEnableObservable: Observable<Int> {
        cancelEnableRelay.asObservable()
    }

    var accountType: AccountType {
        account.type
    }

    func set(filter: String) {
        self.filter = filter

        syncTokens()
    }

    func enable(index: Int) {
        let token = tokens[index]

        if !token.blockchainType.restoreSettingTypes.isEmpty {
            restoreSettingsService.approveSettings(token: token, account: account)
        } else {
            save(token: token)

            stat(page: .coinManager, event: .enableToken(token: token))
        }
    }

    func disable(index: Int) {
        let token = tokens[index]
        let walletsToDelete = wallets.filter { $0.token == token }
        walletManager.delete(wallets: Array(walletsToDelete))

        stat(page: .coinManager, event: .disableToken(token: token))
    }

    func infoItem(index: Int) -> InfoItem? {
        let token = tokens[index]
        let blockchainType = token.blockchainType

        switch token.type {
        case .derived: return InfoItem(token: token, type: .derivation)
        case .addressType: return InfoItem(token: token, type: .bitcoinCashCoinType)
        default: ()
        }

        for restoreSettingType in blockchainType.restoreSettingTypes {
            switch restoreSettingType {
            case .birthdayHeight:
                let settings = restoreSettingsService.settings(accountId: account.id, blockchainType: blockchainType)
                if let birthdayHeight = settings.birthdayHeight {
                    return InfoItem(token: token, type: .birthdayHeight(height: birthdayHeight))
                }
            }
        }

        switch token.type {
        case let .eip20(address):
            return InfoItem(token: token, type: .contractAddress(value: address, explorerUrl: token.blockchain.explorerUrl(reference: address)))
        case let .jetton(address):
            return InfoItem(token: token, type: .contractAddress(value: address, explorerUrl: token.blockchain.explorerUrl(reference: address)))
        case let .stellar(code, issuer):
            let assetId = [code, issuer].joined(separator: "-")
            return InfoItem(token: token, type: .contractAddress(value: assetId, explorerUrl: token.blockchain.explorerUrl(reference: assetId)))
        default:
            return nil
        }
    }
}

extension ManageWalletsService {
    struct Item {
        let token: Token
        let enabled: Bool
        let hasInfo: Bool
    }

    struct InfoItem {
        let token: Token
        let type: InfoType
    }

    enum InfoType {
        case derivation
        case bitcoinCashCoinType
        case birthdayHeight(height: Int)
        case contractAddress(value: String, explorerUrl: String?)
    }
}

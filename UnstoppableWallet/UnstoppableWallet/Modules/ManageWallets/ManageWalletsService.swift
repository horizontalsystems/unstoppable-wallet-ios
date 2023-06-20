import RxSwift
import RxRelay
import MarketKit
import EvmKit

class ManageWalletsService {
    private let account: Account
    private let marketKit: MarketKit.Kit
    private let walletManager: WalletManager
    private let restoreSettingsService: RestoreSettingsService
    private let disposeBag = DisposeBag()

    private var configuredTokens = [ConfiguredToken]()
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
        syncConfiguredTokens()
        sortConfiguredTokens()
        syncState()
    }

    private func handleApproveRestoreSettings(token: Token, settings: RestoreSettings = [:]) {
        if !settings.isEmpty {
            restoreSettingsService.save(settings: settings, account: account, blockchainType: token.blockchainType)
        }

        save(configuredToken: ConfiguredToken(token: token))
    }

    private func handleRejectApproveRestoreSettings(token: Token) {
        guard let index = configuredTokens.firstIndex(where: { $0.token == token }) else {
            return
        }

        cancelEnableRelay.accept(index)
    }

    private func fetchConfiguredTokens() -> [ConfiguredToken] {
        do {
            if filter.trimmingCharacters(in: .whitespaces).isEmpty {
                let queries = [
                    TokenQuery(blockchainType: .bitcoin, tokenType: .native),
                    TokenQuery(blockchainType: .ethereum, tokenType: .native),
                    TokenQuery(blockchainType: .binanceSmartChain, tokenType: .native),
                ]

                let tokens = try marketKit.tokens(queries: queries)

                let featuredConfiguredTokens = tokens
                        .map { $0.configuredTokens }
                        .flatMap { $0 }
                        .filter { account.type.supports(configuredToken: $0) }

                let enabledConfiguredTokens = wallets.map { $0.configuredToken }

                return Array(Set(featuredConfiguredTokens + enabledConfiguredTokens))
            } else if let ethAddress = try? EvmKit.Address(hex: filter) {
                let address = ethAddress.hex
                let tokens = try marketKit.tokens(reference: address)

                return tokens
                        .map { $0.configuredTokens }
                        .flatMap { $0 }
                        .filter { account.type.supports(configuredToken: $0) }
            } else {
                let allFullCoins = try marketKit.fullCoins(filter: filter, limit: 100)
                let tokens = allFullCoins.map { $0.tokens }.flatMap { $0 }

                return tokens
                        .map { $0.configuredTokens }
                        .flatMap { $0 }
                        .filter { account.type.supports(configuredToken: $0) }
            }
        } catch {
            return []
        }
    }

    private func syncConfiguredTokens() {
        configuredTokens = fetchConfiguredTokens()
    }

    private func isEnabled(configuredToken: ConfiguredToken) -> Bool {
        wallets.contains { $0.configuredToken == configuredToken }
    }

    private func sortConfiguredTokens() {
        configuredTokens.sort { lhsConfiguredToken, rhsConfiguredToken in
            let lhsEnabled = isEnabled(configuredToken: lhsConfiguredToken)
            let rhsEnabled = isEnabled(configuredToken: rhsConfiguredToken)

            if lhsEnabled != rhsEnabled {
                return lhsEnabled
            }

            if !filter.isEmpty {
                let filter = filter.lowercased()

                let lhsExactCode = lhsConfiguredToken.coin.code.lowercased() == filter
                let rhsExactCode = rhsConfiguredToken.coin.code.lowercased() == filter

                if lhsExactCode != rhsExactCode {
                    return lhsExactCode
                }

                let lhsStartsWithCode = lhsConfiguredToken.coin.code.lowercased().starts(with: filter)
                let rhsStartsWithCode = rhsConfiguredToken.coin.code.lowercased().starts(with: filter)

                if lhsStartsWithCode != rhsStartsWithCode {
                    return lhsStartsWithCode
                }

                let lhsStartsWithName = lhsConfiguredToken.coin.name.lowercased().starts(with: filter)
                let rhsStartsWithName = rhsConfiguredToken.coin.name.lowercased().starts(with: filter)

                if lhsStartsWithName != rhsStartsWithName {
                    return lhsStartsWithName
                }
            }

            let lhsMarketCapRank = lhsConfiguredToken.coin.marketCapRank ?? Int.max
            let rhsMarketCapRank = rhsConfiguredToken.coin.marketCapRank ?? Int.max

            if lhsMarketCapRank != rhsMarketCapRank {
                return lhsMarketCapRank < rhsMarketCapRank
            }

            let lhsName = lhsConfiguredToken.coin.name.lowercased()
            let rhsName = rhsConfiguredToken.coin.name.lowercased()

            if lhsName != rhsName {
                return lhsName < rhsName
            }

            let lhsOrder = lhsConfiguredToken.blockchainType.order
            let rhsOrder = rhsConfiguredToken.blockchainType.order

            if lhsOrder != rhsOrder {
                return lhsOrder < rhsOrder
            }

            return lhsConfiguredToken.coinSettings.order < rhsConfiguredToken.coinSettings.order
        }
    }

    private func sync(wallets: [Wallet]) {
        self.wallets = Set(wallets)
    }

    private func hasInfo(configuredToken: ConfiguredToken, enabled: Bool) -> Bool {
        if configuredToken.blockchainType.coinSettingType != nil {
            return true
        }

        if !configuredToken.blockchainType.restoreSettingTypes.isEmpty, enabled {
            return true
        }

        switch configuredToken.token.type {
        case .eip20, .bep2: return true
        default: return false
        }
    }

    private func item(configuredToken: ConfiguredToken) -> Item {
        let enabled = isEnabled(configuredToken: configuredToken)

        return Item(
                configuredToken: configuredToken,
                enabled: enabled,
                hasInfo: hasInfo(configuredToken: configuredToken, enabled: enabled)
        )
    }

    private func syncState() {
        items = configuredTokens.map { item(configuredToken: $0) }
    }

    private func handleUpdated(wallets: [Wallet]) {
        sync(wallets: wallets)

        let newConfiguredTokens = fetchConfiguredTokens()

        if newConfiguredTokens.count > configuredTokens.count {
            configuredTokens = newConfiguredTokens
            sortConfiguredTokens()
        }

        syncState()
    }

    private func save(configuredToken: ConfiguredToken) {
        let wallet = Wallet(configuredToken: configuredToken, account: account)
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

        syncConfiguredTokens()
        sortConfiguredTokens()
        syncState()
    }

    func enable(index: Int) {
        let configuredToken = configuredTokens[index]

        if !configuredToken.blockchainType.restoreSettingTypes.isEmpty {
            restoreSettingsService.approveSettings(token: configuredToken.token, account: account)
        } else {
            save(configuredToken: configuredToken)
        }
    }

    func disable(index: Int) {
        let configuredToken = configuredTokens[index]
        let walletsToDelete = wallets.filter { $0.configuredToken == configuredToken }
        walletManager.delete(wallets: Array(walletsToDelete))
    }

    func infoItem(index: Int) -> InfoItem? {
        let configuredToken = configuredTokens[index]
        let blockchainType = configuredToken.blockchainType
        let token = configuredToken.token

        if let coinSettingType = blockchainType.coinSettingType {
            switch coinSettingType {
            case .derivation: return InfoItem(token: token, type: .derivation)
            case .bitcoinCashCoinType: return InfoItem(token: token, type: .bitcoinCashCoinType)
            }
        }

        for restoreSettingType in blockchainType.restoreSettingTypes {
            switch restoreSettingType {
            case .birthdayHeight:
                let settings = restoreSettingsService.settings(account: account, blockchainType: blockchainType)
                if let birthdayHeight = settings.birthdayHeight {
                    return InfoItem(token: token, type: .birthdayHeight(height: birthdayHeight))
                }
            }
        }

        switch token.type {
        case .eip20(let address):
            return InfoItem(token: token, type: .contractAddress(value: address, explorerUrl: configuredToken.blockchain.eip20TokenUrl(address: address)))
        case .bep2(let symbol):
            return InfoItem(token: token, type: .contractAddress(value: symbol, explorerUrl: configuredToken.blockchain.bep2TokenUrl(symbol: symbol)))
        default: return nil
        }
    }

}

extension ManageWalletsService {

    struct Item {
        let configuredToken: ConfiguredToken
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

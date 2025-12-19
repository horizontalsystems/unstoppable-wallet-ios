import Combine
import Foundation
import MarketKit

class ManageWalletsViewModel2: ObservableObject {
    private let account: Account
    private let walletManager = Core.shared.walletManager
    private let restoreSettingsService: RestoreSettingsService

    private let tokenFetcher = ManageWalletsTokenFetcher()
    private let tokenSorter = ManageWalletsTokenSorter()
    private let tokenInfoProvider: ManageWalletsTokenInfoProvider

    private var tokens = [Token]()
    private var wallets = Set<Wallet>()
    private var cancellables = Set<AnyCancellable>()

    @Published var items = [Item]()
    @Published var enabledTokens: [Int: Bool] = [:]

    @Published var filter = ""

    let blockchains: [Blockchain]
    @Published var blockchainFilter: Blockchain? = nil {
        didSet {
            guard blockchainFilter != oldValue else {
                return
            }

            reloadTokens()
        }
    }

    var canAddToken: Bool {
        account.type.canAddTokens
    }

    init(account: Account, restoreSettingsService: RestoreSettingsService) {
        self.account = account
        self.restoreSettingsService = restoreSettingsService
        self.tokenInfoProvider = ManageWalletsTokenInfoProvider(restoreSettingsService: restoreSettingsService)

        wallets = Set(walletManager.activeWallets)

        let supported = (try? Core.shared.marketKit.blockchains(uids: BlockchainType.supported.map(\.uid))) ?? []
        
        blockchains = supported.sorted(by: { $0.type.order < $1.type.order })
        setupBindings()
        reloadTokens()
    }

    private func setupBindings() {
        $filter
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.global(qos: .userInitiated))
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.reloadTokens()
            }
            .store(in: &cancellables)

        walletManager.activeWalletDataUpdatedPublisher
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self] walletData in
                self?.handleWalletsUpdated(walletData.wallets)
            }
            .store(in: &cancellables)

        restoreSettingsService.approveSettingsPublisher
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self] tokenWithSettings in
                self?.handleApproveRestoreSettings(token: tokenWithSettings.token, settings: tokenWithSettings.settings)
            }
            .store(in: &cancellables)

        restoreSettingsService.rejectApproveSettingsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.reloadTokens()
            }
            .store(in: &cancellables)
    }

    private func reloadTokens() {
        let enabledTokens = wallets
            .map(\.token)
            
        let fetched = tokenFetcher.fetch(
            filter: filter,
            account: account,
            preferredTokens: enabledTokens,
            allowedBlockchainTypes: blockchainFilter.map { [$0.type] }
        )
        let sorted = tokenSorter.sorted(fetched, filter: filter, preferredTokens: enabledTokens)

        tokens = sorted
        reloadItems()
    }
    
    private func reloadItems() {
        var enabled: [Int: Bool] = [:]
        let items = tokens.map { token in
            let (item, isEnabled) = item(token: token)
            enabled[token.hashValue] = isEnabled

            return item
        }
        
        DispatchQueue.main.async {
            self.items = items
            self.enabledTokens = enabled
        }
    }

    private func item(token: Token) -> (Item, Bool) {
        let isEnabled = wallets.contains { $0.token == token }

        return (
            Item(
                token: token,
                hasInfo: tokenInfoProvider.hasInfo(token: token, isEnabled: isEnabled)
            ),
            isEnabled
        )
    }

    private func handleWalletsUpdated(_ newWallets: [Wallet]) {
        wallets = Set(newWallets)
        reloadItems()
    }

    private func handleApproveRestoreSettings(token: Token, settings: RestoreSettings) {
        if !settings.isEmpty {
            restoreSettingsService.save(settings: settings, account: account, blockchainType: token.blockchainType)
        }

        saveWallet(for: token)
    }

    private func saveWallet(for token: Token) {
        let wallet = Wallet(token: token, account: account)
        walletManager.save(wallets: [wallet])
    }
}

extension ManageWalletsViewModel2 {
    var blockchainFilterIndex: Int {
        guard let blockchainFilter, let index = blockchains.firstIndex(of: blockchainFilter) else { // all
            return 0
        }

        return index + 1
    }
    
    func setBlockchainFilter(index: Int) {
        if index <= 0 {
            blockchainFilter = nil
        } else {
            blockchainFilter = blockchains[index - 1]
        }
    }

    func toggle(item: Item, enabled: Bool) {
        if enabled {
            enable(token: item.token)
        } else {
            disable(token: item.token)
        }
    }

    func showInfo(item: Item) -> ManageWalletsTokenInfoProvider.InfoItem? {
        guard let infoItem = tokenInfoProvider.infoItem(token: item.token, accountId: account.id) else {
            return nil
        }

        stat(page: .coinManager, event: .openTokenInfo(token: item.token))

        return infoItem
    }

    private func enable(token: Token) {
        if !token.blockchainType.restoreSettingTypes.isEmpty {
            restoreSettingsService.approveSettings(token: token, account: account)
        } else {
            saveWallet(for: token)
            stat(page: .coinManager, event: .enableToken(token: token))
        }
    }

    private func disable(token: Token) {
        let walletsToDelete = wallets.filter { $0.token == token }
        walletManager.delete(wallets: Array(walletsToDelete))
        stat(page: .coinManager, event: .disableToken(token: token))
    }
}

extension ManageWalletsViewModel2 {
    struct Item: Identifiable, Equatable, Hashable {
        let token: Token
        let hasInfo: Bool

        var id: Int { token.hashValue }

        static func == (lhs: Item, rhs: Item) -> Bool {
            lhs.id == rhs.id && lhs.hasInfo == rhs.hasInfo
        }
    }
}

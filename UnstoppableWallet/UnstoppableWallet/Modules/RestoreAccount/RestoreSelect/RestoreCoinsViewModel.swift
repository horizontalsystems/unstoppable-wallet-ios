import Combine
import MarketKit
import SwiftUI

class RestoreCoinsViewModel: ObservableObject {
    private let accountName: String
    private let accountType: AccountType
    private let statPage: StatPage
    private let isManualBackedUp: Bool
    private let isFileBackedUp: Bool

    private let accountFactory = Core.shared.accountFactory
    private let accountManager = Core.shared.accountManager
    private let walletManager = Core.shared.walletManager
    private let restoreStateManager = Core.shared.restoreStateManager
    private let restoreSettingsManager = Core.shared.restoreSettingsManager
    private let marketKit = Core.shared.marketKit

    @Published private(set) var items: [Item] = []
    @Published private(set) var canRestore: Bool = false

    private var blockchainTokens: [Blockchain: [Token]] = [:]
    private var enabledTokens = Set<Token>()
    private var restoreSettingsMap: [Token: RestoreSettings] = [:]

    private var pendingTokenRequest: TokenRequest?
    private var birthdayEntered = false

    init(
        accountName: String,
        accountType: AccountType,
        statPage: StatPage,
        isManualBackedUp: Bool = true,
        isFileBackedUp: Bool = false
    ) {
        self.accountName = accountName
        self.accountType = accountType
        self.statPage = statPage
        self.isManualBackedUp = isManualBackedUp
        self.isFileBackedUp = isFileBackedUp

        loadBlockchains()
        syncItems()
    }

    private func loadBlockchains() {
        let queries = BlockchainType.supported.map(\.nativeTokenQueries).flatMap { $0 }
        let allTokens = (try? marketKit.tokens(queries: queries)) ?? []
        let supported = allTokens.filter { accountType.supports(token: $0) }
        blockchainTokens = Dictionary(grouping: supported, by: { $0.blockchain })
    }

    private func syncItems() {
        let blockchains = blockchainTokens.keys.sorted { $0.type.order < $1.type.order }
        items = blockchains.map { blockchain in
            let isEnabled = enabledTokens.contains { $0.blockchain == blockchain }
            let hasMultipleTokens = (blockchainTokens[blockchain]?.count ?? 0) > 1
            return Item(
                blockchain: blockchain,
                isEnabled: isEnabled,
                hasSettings: isEnabled && hasMultipleTokens
            )
        }
    }

    private func syncCanRestore() {
        canRestore = !enabledTokens.isEmpty
    }
}

extension RestoreCoinsViewModel {
    func toggle(blockchain: Blockchain, isEnabled: Bool) {
        if isEnabled {
            enable(blockchain: blockchain)
        } else {
            disable(blockchain: blockchain)
        }
    }

    func enable(blockchain: Blockchain) {
        guard let tokens = blockchainTokens[blockchain], let firstToken = tokens.first else {
            return
        }

        if tokens.count > 1 {
            requestTokenSelection(
                blockchain: blockchain,
                tokens: tokens,
                currentlyEnabled: tokens.filter(\.type.isDefault),
                allowEmpty: false
            )
        } else if !blockchain.type.restoreSettingTypes.isEmpty {
            requestRestoreSettings(token: firstToken)
        } else {
            handleApprove(blockchain: blockchain, tokens: [firstToken])
        }
    }

    func disable(blockchain: Blockchain) {
        enabledTokens = enabledTokens.filter { $0.blockchain != blockchain }
        for token in restoreSettingsMap.keys where token.blockchain == blockchain {
            restoreSettingsMap.removeValue(forKey: token)
        }
        syncItems()
        syncCanRestore()
    }

    func configure(blockchain: Blockchain) {
        guard let tokens = blockchainTokens[blockchain] else { return }
        let currentlyEnabled = enabledTokens.filter { $0.blockchain == blockchain }
        requestTokenSelection(
            blockchain: blockchain,
            tokens: tokens,
            currentlyEnabled: Array(currentlyEnabled),
            allowEmpty: true
        )
    }

    func restore(onRestore: @escaping () -> Void) {
        let account = accountFactory.account(
            type: accountType,
            origin: .restored,
            backedUp: isManualBackedUp,
            fileBackedUp: isFileBackedUp,
            name: accountName
        )
        accountManager.save(account: account)

        for (token, settings) in restoreSettingsMap {
            restoreSettingsManager.save(settings: settings, account: account, blockchainType: token.blockchainType)
        }

        guard !enabledTokens.isEmpty else {
            return
        }

        for blockchainType in Set(enabledTokens.map(\.blockchainType)) {
            restoreStateManager.setShouldRestore(account: account, blockchainType: blockchainType)
        }

        let wallets = enabledTokens.map { Wallet(token: $0, account: account) }
        walletManager.save(wallets: wallets)

        stat(page: statPage, event: .importWallet(walletType: accountType.statDescription))
        HudHelper.instance.show(banner: .imported)
        onRestore()
    }
}

extension RestoreCoinsViewModel {
    private func handleApprove(blockchain: Blockchain, tokens: [Token]) {
        let existingTokens = enabledTokens.filter { $0.blockchain == blockchain }
        let newTokens = tokens.filter { !existingTokens.contains($0) }
        let removedTokens = existingTokens.filter { !tokens.contains($0) }

        for token in newTokens {
            enabledTokens.insert(token)
        }
        for token in removedTokens {
            enabledTokens.remove(token)
        }

        syncItems()
        syncCanRestore()
    }

    private func requestRestoreSettings(token: Token) {
        guard let provider = BirthdayInputProviderFactory.provider(blockchainType: token.blockchainType) else {
            return
        }

        birthdayEntered = false
        Coordinator.shared.present { [weak self] _ in
            BirthdayInputView(blockchain: token.blockchain, provider: provider) { height in
                self?.handleBirthdayEntered(token: token, height: height)
            }
        } onDismiss: { [weak self] in
            guard let self else { return }
            if !birthdayEntered {
                syncItems() // revert toggle in UI
            }
        }
    }

    private func handleBirthdayEntered(token: Token, height: Int) {
        birthdayEntered = true
        var settings = RestoreSettings()
        settings[.birthdayHeight] = String(height)
        restoreSettingsMap[token] = settings
        enabledTokens.insert(token)
        syncItems()
        syncCanRestore()
    }

    private func requestTokenSelection(
        blockchain: Blockchain,
        tokens: [Token],
        currentlyEnabled: [Token],
        allowEmpty: Bool
    ) {
        let orderedTokens = tokens.ordered()
        pendingTokenRequest = TokenRequest(
            blockchain: blockchain,
            tokens: orderedTokens,
            allowEmpty: allowEmpty
        )

        let config = SelectorModule.MultiConfig(
            image: .remote(url: blockchain.type.imageUrl, placeholder: "placeholder_rectangle_32"),
            title: blockchain.name,
            description: "blockchain_settings.description".localized,
            allowEmpty: allowEmpty,
            viewItems: orderedTokens.map { token in
                SelectorModule.ViewItem(
                    title: token.type.title,
                    subtitle: token.type.description,
                    selected: currentlyEnabled.contains(token)
                )
            },
            footer: "blockchain_settings.footer".localized
        )

        Coordinator.shared.present(type: .bottomSheet) { [self] isPresented in
            BottomMultiSelectorView(config: config, delegate: self, isPresented: isPresented)
        }
    }
}

extension RestoreCoinsViewModel: IBottomMultiSelectorDelegate {
    func bottomSelectorOnSelect(indexes: [Int]) {
        guard let request = pendingTokenRequest else { return }
        pendingTokenRequest = nil
        let selected = indexes.map { request.tokens[$0] }
        handleApprove(blockchain: request.blockchain, tokens: selected)
    }

    func bottomSelectorOnCancel() {
        guard let request = pendingTokenRequest else { return }
        pendingTokenRequest = nil
        let stillEnabled = enabledTokens.contains { $0.blockchain == request.blockchain }
        if !stillEnabled {
            syncItems() // revert toggle in UI
        }
    }
}

extension RestoreCoinsViewModel {
    struct Item: Identifiable, Equatable, Hashable {
        let blockchain: Blockchain
        let isEnabled: Bool
        let hasSettings: Bool

        var id: String { blockchain.uid }

        static func == (lhs: Item, rhs: Item) -> Bool {
            lhs.id == rhs.id
                && lhs.isEnabled == rhs.isEnabled
                && lhs.hasSettings == rhs.hasSettings
        }
    }

    fileprivate struct TokenRequest {
        let blockchain: Blockchain
        let tokens: [Token]
        let allowEmpty: Bool
    }
}

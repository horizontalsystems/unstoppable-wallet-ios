import BigInt
import Combine
import Foundation
import NearKit

/// Which of the NEAR accounts a restored phrase controls the wallet opens (Android `NearAccountPickerViewModel`).
class NearAccountPickerViewModel: ObservableObject {
    private static let balanceDecimals = 8

    let publicKey: NearKit.PublicKey
    private let network = Core.shared.nearKitManager.network
    private let rpcUrls: [URL]
    private let onSelect: (String) -> Void
    private let onUseDefault: () -> Void

    @Published var state: State = .loading
    @Published var selectedAccountId: String?

    private var accounts: [Account] = []

    private let finishSubject = PassthroughSubject<Void, Never>()
    var finishPublisher: AnyPublisher<Void, Never> {
        finishSubject.eraseToAnyPublisher()
    }

    init(publicKey: NearKit.PublicKey, onSelect: @escaping (String) -> Void, onUseDefault: @escaping () -> Void) {
        self.publicKey = publicKey
        self.onSelect = onSelect
        self.onUseDefault = onUseDefault
        rpcUrls = Core.shared.nearNodeManager.rpcUrls(network: network)
    }

    private var implicitAccountId: String {
        publicKey.implicitAccountId
    }

    // details only inform the choice: an account whose details fail to load is still listed
    private func account(accountId: String) async -> Account {
        async let state = try? NearKit.Kit.accountState(accountId: accountId, network: network, rpcUrls: rpcUrls, fastNearApiKey: AppConfig.fastNearApiKey)
        async let keys = try? NearKit.Kit.accessKeys(accountId: accountId, network: network, rpcUrls: rpcUrls, fastNearApiKey: AppConfig.fastNearApiKey)

        let accountState = await state
        let fullAccessKeys = await keys?.filter(\.isFullAccess).map(\.publicKey)
        let ownKey = publicKey.description

        return Account(
            accountId: accountId,
            isImplicit: accountId == implicitAccountId,
            available: accountState?.available,
            hasContract: accountState?.hasContract,
            accessLost: accountState.flatMap { state in fullAccessKeys.map { state.exists && !$0.contains(ownKey) } },
            otherFullAccessKeys: fullAccessKeys.map { $0.contains { $0 != ownKey } }
        )
    }

    private func rows() -> [Row] {
        Self.ordered(accounts).map { account in
            let isImplicit = account.accountId == implicitAccountId
            var subtitleParts = [String]()

            if let available = account.available {
                let value = NearAmount.toNear(yocto: available)
                subtitleParts.append(ValueFormatter.instance.formatFull(value: value, decimalCount: Self.balanceDecimals, symbol: "NEAR") ?? "")
            }
            if isImplicit {
                subtitleParts.append("restore.near_account.default_account".localized)
            }

            return Row(
                accountId: account.accountId,
                title: isImplicit ? account.accountId.shortened : account.accountId,
                subtitle: subtitleParts.joined(separator: " · "),
                warnings: Self.warnings(account: account)
            )
        }
    }

    private static func warnings(account: Account) -> [Warning] {
        var warnings = [Warning]()

        if account.accessLost == true {
            warnings.append(.accessLost)
        } else if account.otherFullAccessKeys == true {
            warnings.append(.otherFullAccessKeys)
        }
        if account.hasContract == true {
            warnings.append(.contract)
        }

        return warnings
    }
}

extension NearAccountPickerViewModel {
    /// Spec 2026-10-13 §6.3: a key anyone can add to their own account must not make that account
    /// the default. Full-access keys only, as Android counts them.
    static func group(_ account: Account) -> Group {
        if account.isImplicit {
            return account.accessLost == true ? .implicitLost : .implicitOwn
        }

        guard let hasContract = account.hasContract, let otherFullAccessKeys = account.otherFullAccessKeys else {
            return .namedShared
        }

        return hasContract || otherFullAccessKeys ? .namedShared : .namedOwn
    }

    /// The list: own named accounts, shared named ones, the implicit one, a lost implicit one; richest first in each.
    static func ordered(_ accounts: [Account]) -> [Account] {
        accounts.enumerated()
            .sorted { lhs, rhs in
                let lhsGroup = group(lhs.element)
                let rhsGroup = group(rhs.element)
                if lhsGroup != rhsGroup {
                    return lhsGroup.rawValue < rhsGroup.rawValue
                }
                let lhsAvailable = lhs.element.available ?? 0
                let rhsAvailable = rhs.element.available ?? 0
                if lhsAvailable != rhsAvailable {
                    return lhsAvailable > rhsAvailable
                }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }

    /// The default choice: an own named account, else the own implicit one, else a shared named one, else the lost implicit one.
    static func preselected(_ accounts: [Account]) -> String? {
        let ordered = ordered(accounts)

        for group in [Group.namedOwn, .implicitOwn, .namedShared, .implicitLost] {
            if let account = ordered.first(where: { self.group($0) == group }) {
                return account.accountId
            }
        }

        return nil
    }
}

extension NearAccountPickerViewModel {
    /// Searches the phrase's accounts and loads their details; the list is shown once all are in.
    @MainActor
    func load() async {
        state = .loading

        do {
            // the implicit account comes first and is always listed, even unfunded: the page never
            // closes on its own (Android does, which on iOS flashes the sheet)
            let accountIds = try await NearKit.Kit.findAccounts(publicKey: publicKey, network: network, rpcUrls: rpcUrls, fastNearApiKey: AppConfig.fastNearApiKey)

            let entered = accounts.filter { !accountIds.contains($0.accountId) }
            let found = await withTaskGroup(of: Account.self) { group in
                for accountId in accountIds {
                    group.addTask { await self.account(accountId: accountId) }
                }

                var result = [Account]()
                for await account in group {
                    result.append(account)
                }
                return result
            }

            // keep the search's order: implicit first, then the index's order
            accounts = accountIds.compactMap { accountId in found.first { $0.accountId == accountId } } + entered
            if selectedAccountId == nil {
                selectedAccountId = Self.preselected(accounts)
            }
            state = .loaded(rows: rows())
        } catch is CancellationError {
            // no-op
        } catch {
            if Task.isCancelled { return }
            state = .failed
        }
    }

    /// An account the user typed and the chain confirmed: listed, if not already, and selected.
    @MainActor
    func add(accountId: String) async {
        if !accounts.contains(where: { $0.accountId == accountId }) {
            await accounts.append(account(accountId: accountId))
        }

        selectedAccountId = accountId
        state = .loaded(rows: rows())
    }

    func select() {
        guard let selectedAccountId else {
            return
        }

        onSelect(selectedAccountId)
        finishSubject.send()
    }

    /// The implicit account, unless the phrase's key is known to be gone from it. A check that fails
    /// lets it through: a failed search is usually the connection, and the implicit account is the phrase's own.
    @MainActor
    func useDefault() async {
        let accountState = try? await NearKit.Kit.accountState(accountId: implicitAccountId, network: network, rpcUrls: rpcUrls, fastNearApiKey: AppConfig.fastNearApiKey)

        if let accountState, accountState.exists,
           let hasFullAccess = try? await NearKit.Kit.hasFullAccess(accountId: implicitAccountId, publicKey: publicKey, network: network, rpcUrls: rpcUrls, fastNearApiKey: AppConfig.fastNearApiKey),
           !hasFullAccess
        {
            HudHelper.instance.show(banner: .error(string: "restore.near_account.access_lost".localized))
            return
        }

        onUseDefault()
        finishSubject.send()
    }
}

extension NearAccountPickerViewModel {
    enum State {
        case loading
        case loaded(rows: [Row])
        case failed
    }

    struct Row: Identifiable, Equatable {
        let accountId: String
        let title: String
        let subtitle: String
        let warnings: [Warning]

        var id: String { accountId }
    }

    enum Warning: Equatable {
        case accessLost
        case otherFullAccessKeys
        case contract
    }

    enum Group: Int {
        case namedOwn
        case namedShared
        case implicitOwn
        case implicitLost
    }

    struct Account {
        let accountId: String
        let isImplicit: Bool
        let available: BigUInt?
        let hasContract: Bool?
        /// The account exists but the phrase's key is not among its full-access keys; nil when unknown.
        let accessLost: Bool?
        /// A key other than the phrase's can also sign anything for the account; nil when unknown.
        let otherFullAccessKeys: Bool?
    }
}

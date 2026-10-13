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

    private func account(accountId: String) async -> Account {
        let state = try? await NearKit.Kit.accountState(accountId: accountId, network: network, rpcUrls: rpcUrls, fastNearApiKey: AppConfig.fastNearApiKey)
        return Account(accountId: accountId, available: state?.available)
    }

    private func rows() -> [Row] {
        accounts.map { account in
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
                subtitle: subtitleParts.joined(separator: " · ")
            )
        }
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
                selectedAccountId = implicitAccountId
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

    func useDefault() {
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

        var id: String { accountId }
    }

    private struct Account {
        let accountId: String
        let available: BigUInt?
    }
}

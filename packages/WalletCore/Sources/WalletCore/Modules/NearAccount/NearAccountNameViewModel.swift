import Combine
import Foundation
import NearKit

/// A NEAR account the phrase controls, typed by hand when the search missed it (Android
/// `NearAccountNameViewModel`): it must exist and the phrase's key must have full access to it.
class NearAccountNameViewModel: ObservableObject {
    private let publicKey: NearKit.PublicKey
    private let network = Core.shared.nearKitManager.network
    private let rpcUrls: [URL]
    private let onEnterAccountId: (String) -> Void

    private var checkTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var state: State = .idle
    @Published var name: String = ""

    init(publicKey: NearKit.PublicKey, onEnterAccountId: @escaping (String) -> Void) {
        self.publicKey = publicKey
        self.onEnterAccountId = onEnterAccountId
        rpcUrls = Core.shared.nearNodeManager.rpcUrls(network: network)

        $name
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.checkTask?.cancel()
                self?.checkTask = nil
                self?.state = .idle
            }
            .store(in: &cancellables)
    }
}

extension NearAccountNameViewModel {
    var loading: Bool {
        state == .loading
    }

    // a refused name stays refused until it is edited (editing resets the state to idle); a failed
    // check can be tried again as is
    var buttonEnabled: Bool {
        switch state {
        case .idle, .checkFailed: return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .loading, .failed: return false
        }
    }

    var cautionState: CautionState {
        switch state {
        case let .failed(text): return .caution(Caution(text: text, type: .error))
        case .checkFailed: return .caution(Caution(text: "restore.near_account_name.check_failed".localized, type: .error))
        default: return .none
        }
    }

    func add() {
        let accountId = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard NearKit.Kit.isValid(accountId: accountId) else {
            state = .failed(text: "restore.near_account_name.invalid".localized)
            return
        }

        state = .loading

        checkTask = Task { [weak self, publicKey, network, rpcUrls] in
            let result: State

            do {
                let accountState = try await NearKit.Kit.accountState(accountId: accountId, network: network, rpcUrls: rpcUrls, fastNearApiKey: AppConfig.fastNearApiKey)
                if !accountState.exists {
                    result = .failed(text: "restore.near_account_name.not_found".localized)
                } else if try await !NearKit.Kit.hasFullAccess(accountId: accountId, publicKey: publicKey, network: network, rpcUrls: rpcUrls, fastNearApiKey: AppConfig.fastNearApiKey) {
                    result = .failed(text: "restore.near_account_name.no_access".localized)
                } else {
                    result = .idle
                }
            } catch {
                result = .checkFailed
            }

            if Task.isCancelled { return }

            await MainActor.run { [weak self] in
                self?.state = result
                if result == .idle {
                    self?.onEnterAccountId(accountId)
                }
            }
        }
    }
}

extension NearAccountNameViewModel {
    enum State: Equatable {
        case idle
        case loading
        case failed(text: String)
        case checkFailed
    }
}

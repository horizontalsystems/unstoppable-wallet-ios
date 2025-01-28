import Combine
import Foundation
import MarketKit

class AddressViewModel: ObservableObject {
    private let wallet: Wallet
    let issueTypes: [AddressSecurityIssueType]
    private var cancellables = Set<AnyCancellable>()

    @Published var address: String = ""
    @Published var addressResult: AddressInput.Result = .idle {
        didSet {
            syncAddressState()
        }
    }

    @Published var state: State = .empty

    @Published var checkStates = [AddressSecurityIssueType: CheckState]() {
        didSet {
            syncValidState()
        }
    }

    init(wallet: Wallet, address: String?) {
        self.wallet = wallet
        issueTypes = AddressSecurityIssueType.issueTypes(blockchainType: wallet.token.blockchainType)

        defer {
            if let address {
                self.address = address
            }
        }
    }

    private func syncAddressState() {
        switch addressResult {
        case .idle:
            state = .empty
        case .loading, .invalid:
            state = .invalid
        case let .valid(success):
            check(address: success.address)
        }
    }

    private func check(address: Address) {
        for type in issueTypes {
            checkStates[type] = .checking
        }

        state = .checking

        for type in issueTypes {
            let checker = AddressSecurityCheckerFactory.addressSecurityChecker(type: type)

            Task {
                do {
                    let hasIssue = try await checker.check(address: address)

                    await MainActor.run {
                        checkStates[type] = hasIssue ? .detected : .clear
                    }
                } catch {
                    await MainActor.run {
                        checkStates[type] = .notAvailable
                    }
                }
            }
        }
    }

    private func syncValidState() {
        guard case .checking = state else {
            return
        }

        var detectedTypes = [AddressSecurityIssueType]()

        for type in issueTypes {
            let checkState = checkStates[type] ?? .notAvailable

            switch checkState {
            case .checking:
                return
            case .detected:
                detectedTypes.append(type)
            default: ()
            }
        }

        let resolvedAddress = ResolvedAddress(address: address, issueTypes: detectedTypes)
        state = .valid(resolvedAddress: resolvedAddress)
    }
}

extension AddressViewModel {
    var token: Token {
        wallet.token
    }
}

extension AddressViewModel {
    enum State {
        case empty
        case invalid
        case checking
        case valid(resolvedAddress: ResolvedAddress)
    }

    enum CheckState {
        case checking
        case clear
        case detected
        case notAvailable
        case locked
    }
}

import Combine
import Foundation
import MarketKit

class AddressSecurityCheckViewModel: ObservableObject {
    private let purchaseManager = Core.shared.purchaseManager
    private let securityManager = Core.shared.securityManager

    let token: Token
    let issueTypes: [AddressSecurityIssueType]
    private var cancellables = Set<AnyCancellable>()

    private var premiumEnabled: Bool

    @Published private(set) var checkStates = [AddressSecurityIssueType: CheckState]()

    @Published private(set) var state: State = .idle

    init(token: Token) {
        self.token = token
        issueTypes = AddressSecurityIssueType.issueTypes(token: token)
        premiumEnabled = purchaseManager.activated(.secureSend)

        purchaseManager.$activeFeatures
            .receive(on: DispatchQueue.main)
            .sink { [weak self] features in
                self?.premiumEnabled = features.contains(.secureSend)
                self?.sync()
            }
            .store(in: &cancellables)

        securityManager.$securityChecks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.sync() }
            .store(in: &cancellables)
    }

    private func sync() {
        guard let address = currentAddress else {
            checkStates = [:]
            state = .idle
            return
        }

        if premiumEnabled {
            var states = [AddressSecurityIssueType: CheckState]()
            var hasEnabledChecks = false

            for type in issueTypes {
                if securityManager.isCheckEnabled(type) {
                    hasEnabledChecks = true
                    states[type] = .checking
                } else {
                    states[type] = .disabled
                }
            }

            checkStates = states

            if hasEnabledChecks {
                check(address: address)
            } else {
                state = .completed(detectedTypes: [])
            }
        } else {
            var states = [AddressSecurityIssueType: CheckState]()
            for type in issueTypes {
                states[type] = .locked
            }
            checkStates = states
            state = .completed(detectedTypes: [])
        }
    }

    private func check(address: Address) {
        let enabledTypes = issueTypes.filter { securityManager.isCheckEnabled($0) }

        state = .checking

        for type in enabledTypes {
            let checker = AddressSecurityCheckerFactory.addressSecurityChecker(type: type)

            Task { [weak self, token] in
                let result: CheckState
                do {
                    let isClear = try await checker.isClear(address: address, token: token)
                    result = isClear ? .clear : .detected
                } catch {
                    result = .notAvailable
                }

                await self?.applyResult(result, type: type, for: address)
            }
        }
    }

    @MainActor
    private func applyResult(_ result: CheckState, type: AddressSecurityIssueType, for address: Address) {
        guard currentAddress?.raw == address.raw else { return }

        checkStates[type] = result
        syncCompleted()
    }

    private func syncCompleted() {
        for type in issueTypes {
            if checkStates[type] == .checking {
                return
            }
        }

        let detectedTypes = issueTypes.filter { checkStates[$0] == .detected }
        state = .completed(detectedTypes: detectedTypes)
    }

    private var currentAddress: Address?

    func check(address: Address?) {
        currentAddress = address
        sync()
    }
}

extension AddressSecurityCheckViewModel {
    enum State {
        case idle
        case checking
        case completed(detectedTypes: [AddressSecurityIssueType])
    }

    enum CheckState {
        case checking
        case clear
        case detected
        case notAvailable
        case locked
        case disabled
    }
}

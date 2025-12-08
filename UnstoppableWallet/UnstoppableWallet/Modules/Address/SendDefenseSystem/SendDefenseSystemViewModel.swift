import Combine
import Foundation
import MarketKit

class SendDefenseSystemViewModel: ObservableObject {
    private let purchaseManager = Core.shared.purchaseManager
    private let appSettingManager = Core.shared.appSettingManager

    private let token: Token
    let destination: AddressViewModel.Destination
    private let issueTypes: [AddressSecurityIssueType]

    private var currentAddress: Address?
    private var tasks = [AddressSecurityIssueType: Task<Void, Never>]()
    private var cancellables = Set<AnyCancellable>()

    private var premiumEnabled: Bool {
        didSet {
            if let currentAddress {
                set(address: currentAddress)
            }
        }
    }

    @Published private(set) var checkStates = [AddressSecurityIssueType: State]()
    @Published private(set) var isChecking = false
    @Published private(set) var detectedIssueTypes: [AddressSecurityIssueType] = []

    init(token: Token, destination: AddressViewModel.Destination) {
        self.token = token
        self.destination = destination

        issueTypes = AddressSecurityIssueType.issueTypes(token: token)

        premiumEnabled = purchaseManager.activated(.scamProtection)

        purchaseManager.$activeFeatures
            .map { $0.contains(.scamProtection) }
            .removeDuplicates()
            .sink { [weak self] isPremium in
                self?.premiumEnabled = isPremium
            }
            .store(in: &cancellables)
    }

    func set(address: Address) {
        guard address.raw != currentAddress?.raw else { return }

        cancelAllTasks()

        currentAddress = address

        guard appSettingManager.recipientAddressCheck else {
            setAllStates(.disabled)
            return
        }

        guard premiumEnabled else {
            setAllStates(.locked)
            return
        }

        performChecks(for: address)
    }

    func reset() {
        cancelAllTasks()
        currentAddress = nil
        checkStates.removeAll()
        syncState()
    }

    private func setAllStates(_ state: State) {
        for type in issueTypes {
            checkStates[type] = state
        }
        syncState()
    }

    private func performChecks(for address: Address) {
        for type in issueTypes {
            checkStates[type] = .checking
        }
        syncState()

        for type in issueTypes {
            let task = Task { [weak self] in
                guard let self else { return }

                let checker = AddressSecurityCheckerFactory.addressSecurityChecker(type: type)

                do {
                    let isClear = try await checker.isClear(address: address, token: token)

                    await MainActor.run { [weak self] in
                        guard let self,
                              currentAddress?.raw == address.raw
                        else {
                            return
                        }

                        checkStates[type] = isClear ? .clear : .detected
                        syncState()
                    }
                } catch {
                    await MainActor.run { [weak self] in
                        guard let self,
                              currentAddress?.raw == address.raw
                        else {
                            return
                        }

                        checkStates[type] = .notAvailable
                        syncState()
                    }
                }
            }

            tasks[type] = task
        }
    }

    private func cancelAllTasks() {
        for task in tasks.values {
            task.cancel()
        }
        tasks.removeAll()
    }

    private func syncState() {
        isChecking = checkStates.values.contains(.checking)

        detectedIssueTypes = issueTypes.filter { type in
            checkStates[type] == .detected
        }
    }
}

extension SendDefenseSystemViewModel {
    enum State {
        case idle
        case checking
        case clear
        case detected
        case notAvailable
        case locked
        case disabled
    }
}

import Combine
import Foundation
import HsExtensions

class TermsManager {
    private static let keyTermsAccepted = "key_terms_accepted"
    private static let keyTermsState = "key_terms_state"
    private let userDefaultsStorage: UserDefaultsStorage

    @DistinctPublished var state: TermsState

    init(userDefaultsStorage: UserDefaultsStorage) {
        self.userDefaultsStorage = userDefaultsStorage

        state = TermsManager.migrateIfNeeded(storage: userDefaultsStorage)
    }
}

extension TermsManager {
    func setTermsAccepted() {
        saveState(TermsState.accepted)
    }

    private func saveState(_ state: TermsState) {
        if let data = try? JSONEncoder().encode(state) {
            userDefaultsStorage.set(value: data, for: Self.keyTermsState)
            self.state = state
        }
    }

    static func migrateIfNeeded(storage: UserDefaultsStorage) -> TermsState {
        // 1. Try to load current state
        if let data: Data = storage.value(for: keyTermsState),
           let state = try? JSONDecoder().decode(TermsState.self, from: data)
        {
            let currentVersion = TermsConfiguration.configurations.count

            // Already on current version
            if state.version == currentVersion {
                return state
            }

            // Migrate to current version
            let migratedState = migrate(from: state, to: currentVersion)

            // Save migrated state
            if let data = try? JSONEncoder().encode(migratedState) {
                storage.set(value: data, for: keyTermsState)
            }

            return migratedState
        }

        // 2. Legacy migration: check old boolean flag
        if let legacyAccepted: Bool = storage.value(for: keyTermsAccepted),
           legacyAccepted
        {
            // User accepted v1 terms, migrate to current version
            let v1State = TermsState(
                version: 1,
                acceptedTermIds: TermsConfiguration.configurations.first?.all ?? []
            )

            let currentVersion = TermsConfiguration.configurations.count
            let migratedState = migrate(from: v1State, to: currentVersion)

            // Save migrated state
            if let data = try? JSONEncoder().encode(migratedState) {
                storage.set(value: data, for: keyTermsState)
            }

            // Clean up legacy key
            storage.set(value: nil as Bool?, for: keyTermsAccepted)

            return migratedState
        }

        // 3. New user - no terms accepted
        return TermsState.notAccepted
    }

    private static func migrate(from oldState: TermsState, to newVersion: Int) -> TermsState {
        guard let newConfiguration = TermsConfiguration.configurations.last else {
            return oldState
        }

        // Keep only terms that still exist in current configuration
        let currentTermIds = newConfiguration.all
        let validAcceptedIds = oldState.acceptedTermIds.intersection(currentTermIds)

        return TermsState(
            version: newVersion,
            acceptedTermIds: validAcceptedIds
        )
    }
}

extension TermsManager {
    struct Term: Identifiable, Codable, Hashable {
        let id: String
        let version: Int

        var localizedKey: String {
            "terms.item.\(id)"
        }

        init(id: String, version: Int = 1) {
            self.id = id
            self.version = version
        }
    }

    struct TermsConfiguration {
        let version: Int
        let terms: [Term]

        static let configurations = [
            TermsConfiguration(
                version: 1,
                terms: [
                    Term(id: "backup_recovery", version: 1),
                    Term(id: "device_pin", version: 1),
                ]
            ),
            TermsConfiguration(
                version: 2,
                terms: [
                    Term(id: "backup_recovery", version: 1),
                    Term(id: "device_pin", version: 1),
                    Term(id: "privacy_notice", version: 1),
                    Term(id: "monetization", version: 1),
                    Term(id: "open_source", version: 1),
                ]
            ),
        ]

        var all: Set<String> {
            Set(terms.map(\.id))
        }

        static var current: TermsConfiguration {
            configurations.last ?? .init(version: 0, terms: [])
        }
    }

    struct TermsState: Codable, Equatable {
        static let notAccepted = TermsState(version: TermsConfiguration.configurations.count, acceptedTermIds: [])
        static let accepted = TermsState(
            version: TermsConfiguration.configurations.count,
            acceptedTermIds: TermsConfiguration.current.all
        )

        let version: Int
        let acceptedTermIds: Set<String>

        init(version: Int, acceptedTermIds: Set<String>) {
            self.version = version
            self.acceptedTermIds = acceptedTermIds
        }

        var allAccepted: Bool {
            guard !TermsConfiguration.current.terms.isEmpty else {
                return false
            }

            return TermsConfiguration.current.all.isSubset(of: acceptedTermIds)
        }
    }
}

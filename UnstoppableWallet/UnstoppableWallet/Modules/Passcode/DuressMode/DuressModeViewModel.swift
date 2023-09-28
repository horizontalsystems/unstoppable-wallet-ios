import Combine

class DuressModeViewModel: ObservableObject {
    private let biometryManager: BiometryManager

    let regularAccounts: [Account]
    let watchAccounts: [Account]

    @Published var selectedAccountIds = Set<String>()

    init(biometryManager: BiometryManager, accountManager: AccountManager) {
        self.biometryManager = biometryManager

        let sortedAccounts = accountManager.accounts.sorted { $0.name.lowercased() < $1.name.lowercased() }
        regularAccounts = sortedAccounts.filter { !$0.watchAccount }
        watchAccounts = sortedAccounts.filter { $0.watchAccount }
    }

    var biometryType: BiometryType? {
        biometryManager.biometryType
    }
}

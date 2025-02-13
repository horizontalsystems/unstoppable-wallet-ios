import Combine
import Foundation

class TonConnectConnectViewModel: ObservableObject {
    private let parameters: TonConnectParameters
    let manifest: TonConnectManifest
    let returnDeepLink: String?

    private let tonConnectManager = App.shared.tonConnectManager
    private let accountManager = App.shared.accountManager

    let eligibleAccounts: [Account]
    @Published var account: Account?

    private let finishSubject = PassthroughSubject<Void, Never>()

    init(config: TonConnectConfig, returnDeepLink: String?) {
        parameters = config.parameters
        manifest = config.manifest
        self.returnDeepLink = returnDeepLink

        eligibleAccounts = accountManager.accounts.filter(\.type.supportsTonConnect).sorted { $0.name < $1.name }

        if let activeAccount = accountManager.activeAccount, eligibleAccounts.contains(activeAccount) {
            account = activeAccount
        } else {
            account = eligibleAccounts.first
        }
    }
}

extension TonConnectConnectViewModel {
    var finishPublisher: AnyPublisher<Void, Never> {
        finishSubject.eraseToAnyPublisher()
    }

    func connect() {
        guard let account else {
            return
        }

        Task {
            try await tonConnectManager.connect(account: account, parameters: parameters, manifest: manifest)

            await MainActor.run {
                finishSubject.send()
            }
        }
    }

    func rejectConnection() {
        Task {
            try await tonConnectManager.rejectConnection(parameters: parameters)
        }
    }
}

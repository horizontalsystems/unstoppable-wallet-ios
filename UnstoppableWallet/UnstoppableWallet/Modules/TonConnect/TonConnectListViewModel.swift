import Combine
import Foundation

class TonConnectListViewModel: ObservableObject {
    private let tonConnectManager = App.shared.tonConnectManager
    private let accountManager = App.shared.accountManager
    private var cancellables = Set<AnyCancellable>()

    private let openCreateConnectionSubject = PassthroughSubject<TonConnectConfig, Never>()

    @Published private(set) var items = [Item]()

    init() {
        syncItems(tonTonnectApps: tonConnectManager.tonConnectApps)

        tonConnectManager.$tonConnectApps
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.syncItems(tonTonnectApps: $0) }
            .store(in: &cancellables)
    }

    private func syncItems(tonTonnectApps: [TonConnectApp]) {
        let dictionary = Dictionary(grouping: tonTonnectApps, by: { $0.accountId })
        let accounts = dictionary.keys.compactMap { accountManager.account(id: $0) }

        items = accounts.sorted { $0.name < $1.name }.compactMap { account in
            guard let apps = dictionary[account.id] else {
                return nil
            }

            return Item(account: account, apps: apps.sorted { $0.manifest.name < $1.manifest.name })
        }
    }
}

extension TonConnectListViewModel {
    var openCreateConnectionPublisher: AnyPublisher<TonConnectConfig, Never> {
        openCreateConnectionSubject.eraseToAnyPublisher()
    }

    func handle(deeplink: String) {
        Task { [tonConnectManager, openCreateConnectionSubject] in
            let config = try await tonConnectManager.loadTonConnectConfiguration(deeplink: deeplink)

            await MainActor.run {
                openCreateConnectionSubject.send(config)
            }
        }
    }

    func disconnect(app: TonConnectApp) {
        Task { [tonConnectManager] in
            try await tonConnectManager.disconnect(tonConnectApp: app)
        }
    }
}

extension TonConnectListViewModel {
    struct Item: Identifiable {
        let account: Account
        let apps: [TonConnectApp]

        var id: ID {
            account.id
        }
    }
}

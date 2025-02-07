import Combine
import Foundation

class PrivacyPolicyViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let purchaseManager = App.shared.purchaseManager
    private let statManager = App.shared.statManager

    @Published private(set) var premiumEnabled: Bool = false
    @Published private(set) var statsEnabled = false

    let config: Config

    init(config: Config) {
        self.config = config

        premiumEnabled = purchaseManager.hasActivePurchase
        purchaseManager.$purchasedProducts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.premiumEnabled = self?.purchaseManager.hasActivePurchase ?? false
                self?.syncStatsEnabled()
            }
            .store(in: &cancellables)

        statManager.allowedPublisher
            .sink { [weak self] _ in self?.syncStatsEnabled() }
            .store(in: &cancellables)

        syncStatsEnabled()
    }

    private func syncStatsEnabled() {
        statsEnabled = statManager.allowed || !premiumEnabled
    }

    func set(allowed: Bool) {
        statManager.allowed = allowed
    }
}

extension PrivacyPolicyViewModel {
    struct Config {
        let title: String
        let description: String

        static var privacy: Config {
            Config(
                title: "settings.privacy".localized,
                description: "settings.privacy.description".localized(AppConfig.appName)
            )
        }
    }
}

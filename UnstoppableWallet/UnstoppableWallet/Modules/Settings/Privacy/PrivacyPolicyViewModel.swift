import Combine
import Foundation

class PrivacyPolicyViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let statManager = App.shared.statManager

    @Published private(set) var statsEnabled = false

    let config: Config

    init(config: Config) {
        self.config = config

        statManager.allowedPublisher
            .sink { [weak self] _ in self?.syncStatsEnabled() }
            .store(in: &cancellables)

        syncStatsEnabled()
    }

    private func syncStatsEnabled() {
        statsEnabled = statManager.allowed
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

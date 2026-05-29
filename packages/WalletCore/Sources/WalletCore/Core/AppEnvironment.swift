public enum AppEnvironment: String {
    case dev
    case prod

    public private(set) static var current: AppEnvironment = .prod

    public static func configure(_ env: AppEnvironment) {
        current = env
    }

    static var config: Config {
        switch current {
        case .dev: return .dev
        case .prod: return .prod
        }
    }
}

extension AppEnvironment {
    struct Config {
        let marketApiUrl: String
        let swapApiUrl: String
        let referralAppServerUrl: String
        let showBuildNumber: Bool
        let showTestSwitchers: Bool

        static let dev = Config(
            marketApiUrl: "https://api-dev.blocksdecoded.com",
            swapApiUrl: "https://swap-dev.unstoppable.money/api",
            referralAppServerUrl: "https://dev-be.unstoppable.money/api",
            showBuildNumber: true,
            showTestSwitchers: true
        )

        static let prod = Config(
            marketApiUrl: "https://api.blocksdecoded.com",
            swapApiUrl: "https://swap-api.unstoppable.money",
            referralAppServerUrl: "https://be.unstoppable.money/api",
            showBuildNumber: false,
            showTestSwitchers: false
        )
    }
}

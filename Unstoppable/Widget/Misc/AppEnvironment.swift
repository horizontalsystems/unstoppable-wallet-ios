enum AppEnvironment: String {
    case dev
    case prod

    static let current: AppEnvironment = {
        #if DEV
            return .dev
        #else
            return .prod
        #endif
    }()

    static var config: Config {
        switch AppEnvironment.current {
        case .dev: return .dev
        case .prod: return .prod
        }
    }
}

extension AppEnvironment {
    struct Config {
        let marketApiUrl: String

        static let dev = Config(
            marketApiUrl: "https://api-dev.blocksdecoded.com"
        )

        static let prod = Config(
            marketApiUrl: "https://api.blocksdecoded.com"
        )
    }
}

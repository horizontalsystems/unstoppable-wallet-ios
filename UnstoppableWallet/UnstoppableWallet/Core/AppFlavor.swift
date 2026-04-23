enum AppFlavor: String {
    case dev
    case prod

    static let current: AppFlavor = {
        #if DEV
            return .dev
        #elseif PROD
            return .prod
        #else
            #error("No app flavor defined. Set DEV or PROD in SWIFT_ACTIVE_COMPILATION_CONDITIONS.")
        #endif
    }()

    var isDev: Bool { self == .dev }
    var isProd: Bool { self == .prod }

    static var config: Config {
        switch AppFlavor.current {
        case .dev: return .dev
        case .prod: return .prod
        }
    }
}

extension AppFlavor {
    struct Config {
        let marketApiUrl: String
        let swapApiUrl: String
        let referralAppServerUrl: String
        let sharedCloudContainerId: String
        let privateCloudContainerId: String
        let showBuildNumber: Bool
        let showTestSwitchers: Bool

        static let dev = Config(
            marketApiUrl: "https://api-dev.blocksdecoded.com",
            swapApiUrl: "https://swap-dev.unstoppable.money/api",
            referralAppServerUrl: "https://dev-be.unstoppable.money/api",
            sharedCloudContainerId: "iCloud.io.horizontalsystems.bank-wallet.shared.dev",
            privateCloudContainerId: "iCloud.io.horizontalsystems.bank-wallet.dev",
            showBuildNumber: true,
            showTestSwitchers: true
        )

        static let prod = Config(
            marketApiUrl: "https://api.blocksdecoded.com",
            swapApiUrl: "https://swap-api.unstoppable.money",
            referralAppServerUrl: "https://be.unstoppable.money/api",
            sharedCloudContainerId: "iCloud.io.horizontalsystems.bank-wallet.shared",
            privateCloudContainerId: "iCloud.io.horizontalsystems.bank-wallet",
            showBuildNumber: false,
            showTestSwitchers: false
        )
    }
}

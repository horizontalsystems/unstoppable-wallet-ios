import Foundation
import MarketKit
import UIKit

enum AppConfig {
    static let label = "io.horizontalsystems.unstoppable"
    static let backupSalt = "unstoppable"

    static let companyName = "Horizontal Systems"
    static let reportEmail = "support.unstoppable@protonmail.com"
    static let companyWebPageLink = "https://horizontalsystems.io"
    static let appWebPageLink = "https://unstoppable.money"
    static let analyticsLink = "https://unstoppable.money/analytics"
    static let privacyPolicyLink = "https://unstoppable.money/privacy-policy"
    static let appleTermsOfServiceLink = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula"
    static let nymVpnLink = "https://nymtechnologies.pxf.io/N9vnr1"
    static let appGitHubAccount = "horizontalsystems"
    static let appGitHubRepository = "unstoppable-wallet-ios"
    static let appTwitterAccount = "unstoppablebyhs"
    static let appTelegramAccount = "unstoppable_announcements"
    static let appTelegramSupportSlug = "-uTI4HwKZWNi"
    static let appTokenTelegramAccount = "BeUnstoppable_bot"
    static let mempoolSpaceUrl = "https://mempool.space"

    static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    }

    static var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
    }

    static var appId: String? {
        UIDevice.current.identifierForVendor?.uuidString
    }

    static var appName: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String) ?? ""
    }

    // static var showBuildNumber: Bool {
    //     AppEnvironment.config.showBuildNumber
    // }

    // static var showTestSwitchers: Bool {
    //     AppEnvironment.config.showTestSwitchers
    // }

    // static var marketApiUrl: String {
    //     AppEnvironment.config.marketApiUrl
    // }

    // static var swapApiUrl: String {
    //     AppEnvironment.config.swapApiUrl
    // }

    static var etherscanKeys: [String] {
        ((Bundle.main.object(forInfoDictionaryKey: "EtherscanApiKeys") as? String) ?? "").components(separatedBy: ",")
    }

    static var arbiscanKeys: [String] {
        ((Bundle.main.object(forInfoDictionaryKey: "ArbiscanApiKeys") as? String) ?? "").components(separatedBy: ",")
    }

    static var gnosisscanKeys: [String] {
        ((Bundle.main.object(forInfoDictionaryKey: "GnosisscanApiKeys") as? String) ?? "").components(separatedBy: ",")
    }

    static var ftmscanKeys: [String] {
        ((Bundle.main.object(forInfoDictionaryKey: "FtmscanApiKeys") as? String) ?? "").components(separatedBy: ",")
    }

    static var optimismEtherscanKeys: [String] {
        ((Bundle.main.object(forInfoDictionaryKey: "OptimismEtherscanApiKeys") as? String) ?? "").components(separatedBy: ",")
    }

    static var basescanKeys: [String] {
        ((Bundle.main.object(forInfoDictionaryKey: "BasescanApiKeys") as? String) ?? "").components(separatedBy: ",")
    }

    static var eraZkSyncKeys: [String] {
        ((Bundle.main.object(forInfoDictionaryKey: "EraZkSyncApiKeys") as? String) ?? "").components(separatedBy: ",")
    }

    static var bscscanKeys: [String] {
        ((Bundle.main.object(forInfoDictionaryKey: "BscscanApiKeys") as? String) ?? "").components(separatedBy: ",")
    }

    static var polygonscanKeys: [String] {
        ((Bundle.main.object(forInfoDictionaryKey: "PolygonscanApiKeys") as? String) ?? "").components(separatedBy: ",")
    }

    static var snowtraceKeys: [String] {
        ((Bundle.main.object(forInfoDictionaryKey: "SnowtraceApiKeys") as? String) ?? "").components(separatedBy: ",")
    }

    static var twitterBearerToken: String? {
        (Bundle.main.object(forInfoDictionaryKey: "TwitterBearerToken") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    static var hsProviderApiKey: String? {
        (Bundle.main.object(forInfoDictionaryKey: "HsProviderApiKey") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    static var tronGridApiKeys: [String] {
        ((Bundle.main.object(forInfoDictionaryKey: "TronGridApiKeys") as? String) ?? "").components(separatedBy: ",")
    }

    static var solanaAlchemyApiKey: String? {
        (Bundle.main.object(forInfoDictionaryKey: "SolanaAlchemyApiKey") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    static var solanaAlchemyApiKeys: [String] {
        ((Bundle.main.object(forInfoDictionaryKey: "SolanaAlchemyApiKeys") as? String) ?? "").components(separatedBy: ",")
    }

    static var walletConnectV2ProjectKey: String? {
        (Bundle.main.object(forInfoDictionaryKey: "WallectConnectV2ProjectKey") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    static var unstoppableDomainsApiKey: String? {
        (Bundle.main.object(forInfoDictionaryKey: "UnstoppableDomainsApiKey") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    static var oneInchApiKey: String? {
        (Bundle.main.object(forInfoDictionaryKey: "OneInchApiKey") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    static var pimlicoApiKey: String? {
        (Bundle.main.object(forInfoDictionaryKey: "PimlicoApiKey") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    static var pimlicoSponsorshipPolicyId: String? {
        (Bundle.main.object(forInfoDictionaryKey: "PimlicoSponsorshipPolicyId") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    static var gasFreeApiKey: String? {
        (Bundle.main.object(forInfoDictionaryKey: "GasFreeApiKey") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    static var gasFreeApiSecret: String? {
        (Bundle.main.object(forInfoDictionaryKey: "GasFreeApiSecret") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    static var oneInchCommissionAddress: String? {
        (Bundle.main.object(forInfoDictionaryKey: "OneInchCommissionAddress") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    static var oneInchCommission: Decimal? {
        (Bundle.main.object(forInfoDictionaryKey: "OneInchCommission") as? String).flatMap {
            $0.isEmpty ? nil : Decimal(string: $0, locale: Locale(identifier: "en_US_POSIX"))
        }
    }

    static var thorchainAffiliate: String? {
        (Bundle.main.object(forInfoDictionaryKey: "ThorchainAffiliate") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    static var thorchainAffiliateBps: Int? {
        (Bundle.main.object(forInfoDictionaryKey: "ThorchainAffiliateBps") as? String).flatMap { $0.isEmpty ? nil : Int($0) }
    }

    static var mayaAffiliate: String? {
        (Bundle.main.object(forInfoDictionaryKey: "MayaAffiliate") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    static var mayaAffiliateBps: Int? {
        (Bundle.main.object(forInfoDictionaryKey: "MayaAffiliateBps") as? String).flatMap { $0.isEmpty ? nil : Int($0) }
    }

    static var uswapApiKey: String? {
        (Bundle.main.object(forInfoDictionaryKey: "USwapApiKey") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    static var jupiterApiKey: String? {
        (Bundle.main.object(forInfoDictionaryKey: "JupiterApiKey") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    // static var referralAppServerUrl: String {
    //     AppEnvironment.config.referralAppServerUrl
    // }

    static var defaultWords: String {
        Bundle.main.object(forInfoDictionaryKey: "DefaultWords") as? String ?? ""
    }

    static var defaultPassphrase: String {
        Bundle.main.object(forInfoDictionaryKey: "DefaultPassphrase") as? String ?? ""
    }

    static var defaultWatchAddress: String? {
        Bundle.main.object(forInfoDictionaryKey: "DefaultWatchAddress") as? String
    }

    static var sharedCloudContainer: String? {
        Bundle.main.object(forInfoDictionaryKey: "SharedCloudContainerId") as? String
    }

    static var privateCloudContainer: String? {
        Bundle.main.object(forInfoDictionaryKey: "PrivateCloudContainerId") as? String
    }

    static var openSeaApiKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "OpenSeaApiKey") as? String) ?? ""
    }

    static var chainalysisApiKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "ChainalysisApiKey") as? String) ?? ""
    }

    static var merkleApiPath: String {
        (Bundle.main.object(forInfoDictionaryKey: "MerkleApiPath") as? String) ?? ""
    }

    static var hashDitApiKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "HashDitApiKey") as? String) ?? ""
    }
}

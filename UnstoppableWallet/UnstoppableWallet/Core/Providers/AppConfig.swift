import Foundation
import UIKit
import MarketKit

struct AppConfig {
    static let label = "io.horizontalsystems.unstoppable"
    static let backupSalt = "unstoppable"

    static let companyName = "Horizontal Systems"
    static let reportEmail = "support.unstoppable@protonmail.com"
    static let companyWebPageLink = "https://horizontalsystems.io"
    static let appWebPageLink = "https://unstoppable.money"
    static let analyticsLink = "https://unstoppable.money/analytics"
    static let appGitHubAccount = "horizontalsystems"
    static let appGitHubRepository = "unstoppable-wallet-ios"
    static let appTwitterAccount = "unstoppablebyhs"
    static let appTelegramAccount = "unstoppable_announcements"
    static let appRedditAccount = "UNSTOPPABLEWallet"
    static let mempoolSpaceUrl = "https://mempool.space"
    static let guidesIndexUrl = URL(string: "https://raw.githubusercontent.com/horizontalsystems/blockchain-crypto-guides/v1.2/index.json")!
    static let faqIndexUrl = URL(string: "https://raw.githubusercontent.com/horizontalsystems/unstoppable-wallet-website/master/src/faq.json")!
    static let donationAddresses: [BlockchainType: String] = [
        .bitcoin: "bc1qxt5u5swx3sk6y2923whr4tvjreza43g37czv67",
        .bitcoinCash: "bitcoincash:qz6sy9fq66yvfl5mvpfv3v2nqw5pervvkc425nj9g0\n",
        .ecash: "ecash:qp6t4rqd4qdlq0vlucjhucjxygn5969j3cdan6ykzr\n",
        .litecoin: "ltc1q05f90wt464h8dft9t7q9sp9n0qeprlv30070at\n",
        .dash: "Xp24AqFUP9nF3ycLCmTDvgezxSt3RAKP2r",
        .zcash: "zs1jpd8u7zghtq5eg48l384y6fpy7cr0xmqehnw5mujpm8v2u7jr9a3j7luftqpthf6a8f720vdfyn",
        .ethereum: "0xA24c159C7f1E4A04dab7c364C2A8b87b3dBa4cd1",
        .binanceSmartChain: "0xA24c159C7f1E4A04dab7c364C2A8b87b3dBa4cd1",
        .binanceChain: "bnb1m0ys77zwg74733f5wwyzhjme2xrdq4ee84smf4",
        .polygon: "0xA24c159C7f1E4A04dab7c364C2A8b87b3dBa4cd1",
        .avalanche: "0xA24c159C7f1E4A04dab7c364C2A8b87b3dBa4cd1",
        .optimism: "0xA24c159C7f1E4A04dab7c364C2A8b87b3dBa4cd1",
        .arbitrumOne: "0xA24c159C7f1E4A04dab7c364C2A8b87b3dBa4cd1",
        .gnosis: "0xA24c159C7f1E4A04dab7c364C2A8b87b3dBa4cd1",
        .fantom: "0xA24c159C7f1E4A04dab7c364C2A8b87b3dBa4cd1",
        .tron: "TQzANCd363w5CjRWDtswm8Y5nFPAdnwekF",
        .solana: "5gattKnvu5f1NDHBuZ6VfDXjRrJa9UcAArkZ3ys3e82F"
    ]

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

    static var marketApiUrl: String {
        (Bundle.main.object(forInfoDictionaryKey: "MarketApiUrl") as? String) ?? ""
    }

    static var officeMode: Bool {
        Bundle.main.object(forInfoDictionaryKey: "OfficeMode") as? String == "true"
    }

    static var infuraCredentials: (id: String, secret: String?) {
        let id = (Bundle.main.object(forInfoDictionaryKey: "InfuraProjectId") as? String) ?? ""
        let secret = Bundle.main.object(forInfoDictionaryKey: "InfuraProjectSecret") as? String
        return (id: id, secret: secret)
    }

    static var etherscanKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "EtherscanApiKey") as? String) ?? ""
    }

    static var arbiscanKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "ArbiscanApiKey") as? String) ?? ""
    }

    static var gnosisscanKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "GnosisscanApiKey") as? String) ?? ""
    }

    static var ftmscanKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "FtmscanApiKey") as? String) ?? ""
    }

    static var optimismEtherscanKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "OptimismEtherscanApiKey") as? String) ?? ""
    }

    static var bscscanKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "BscscanApiKey") as? String) ?? ""
    }

    static var polygonscanKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "PolygonscanApiKey") as? String) ?? ""
    }

    static var snowtraceKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "SnowtraceApiKey") as? String) ?? ""
    }

    static var cryptoCompareApiKey: String? {
        (Bundle.main.object(forInfoDictionaryKey: "CryptoCompareApiKey") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    static var defiYieldApiKey: String? {
        (Bundle.main.object(forInfoDictionaryKey: "DefiYieldApiKey") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    static var twitterBearerToken: String? {
        (Bundle.main.object(forInfoDictionaryKey: "TwitterBearerToken") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    static var hsProviderApiKey: String? {
        (Bundle.main.object(forInfoDictionaryKey: "HsProviderApiKey") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    static var tronGridApiKey: String? {
        (Bundle.main.object(forInfoDictionaryKey: "TronGridApiKey") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    static var walletConnectV2ProjectKey: String? {
        (Bundle.main.object(forInfoDictionaryKey: "WallectConnectV2ProjectKey") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    static var defaultWords: String {
        Bundle.main.object(forInfoDictionaryKey: "DefaultWords") as? String ?? ""
    }

    static var defaultPassphrase: String {
        Bundle.main.object(forInfoDictionaryKey: "DefaultPassphrase") as? String ?? ""
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

}

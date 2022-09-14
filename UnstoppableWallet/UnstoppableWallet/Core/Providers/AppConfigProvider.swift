import Foundation

class AppConfigProvider {
    let companyWebPageLink = "https://horizontalsystems.io"
    let appWebPageLink = "https://unstoppable.money"
    let appGitHubLink = "https://github.com/horizontalsystems/unstoppable-wallet-ios"
    let appTwitterAccount = "unstoppablebyhs"
    let reportEmail = "support.unstoppable@protonmail.com"
    let btcCoreRpcUrl = "https://btc.blocksdecoded.com/rpc"
    let guidesIndexUrl = URL(string: "https://raw.githubusercontent.com/horizontalsystems/blockchain-crypto-guides/v1.2/index.json")!
    let faqIndexUrl = URL(string: "https://raw.githubusercontent.com/horizontalsystems/unstoppable-wallet-website/v1.2/src/faq.json")!

    var marketApiUrl: String {
        (Bundle.main.object(forInfoDictionaryKey: "MarketApiUrl") as? String) ?? ""
    }

    var testMode: Bool {
        Bundle.main.object(forInfoDictionaryKey: "TestMode") as? String == "true"
    }

    var officeMode: Bool {
        Bundle.main.object(forInfoDictionaryKey: "OfficeMode") as? String == "true"
    }

    var infuraCredentials: (id: String, secret: String?) {
        let id = (Bundle.main.object(forInfoDictionaryKey: "InfuraProjectId") as? String) ?? ""
        let secret = Bundle.main.object(forInfoDictionaryKey: "InfuraProjectSecret") as? String
        return (id: id, secret: secret)
    }

    var etherscanKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "EtherscanApiKey") as? String) ?? ""
    }

    var arbiscanKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "ArbiscanApiKey") as? String) ?? ""
    }

    var optimismEtherscanKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "OptimismEtherscanApiKey") as? String) ?? ""
    }

    var bscscanKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "BscscanApiKey") as? String) ?? ""
    }

    var polygonscanKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "PolygonscanApiKey") as? String) ?? ""
    }

    var snowtraceKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "SnowtraceApiKey") as? String) ?? ""
    }

    var cryptoCompareApiKey: String? {
        (Bundle.main.object(forInfoDictionaryKey: "CryptoCompareApiKey") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    var defiYieldApiKey: String? {
        (Bundle.main.object(forInfoDictionaryKey: "DefiYieldApiKey") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    var twitterBearerToken: String? {
        (Bundle.main.object(forInfoDictionaryKey: "TwitterBearerToken") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    var hsProviderApiKey: String? {
        (Bundle.main.object(forInfoDictionaryKey: "HsProviderApiKey") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    var walletConnectV2ProjectKey: String? {
        (Bundle.main.object(forInfoDictionaryKey: "WallectConnectV2ProjectKey") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    var defaultWords: String {
        Bundle.main.object(forInfoDictionaryKey: "DefaultWords") as? String ?? ""
    }

}





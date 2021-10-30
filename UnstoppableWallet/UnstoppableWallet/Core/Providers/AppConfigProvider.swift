import Foundation

class AppConfigProvider: IAppConfigProvider {
    let companyWebPageLink = "https://horizontalsystems.io"
    let appWebPageLink = "https://unstoppable.money"
    let appGitHubLink = "https://github.com/horizontalsystems/unstoppable-wallet-ios"
    let reportEmail = "support.unstoppable@protonmail.com"
    let btcCoreRpcUrl = "https://btc.horizontalsystems.xyz/rpc"

    var guidesIndexUrl: URL {
        URL(string: (Bundle.main.object(forInfoDictionaryKey: "GuidesIndexUrl") as! String))!
    }

    var faqIndexUrl: URL {
        URL(string: (Bundle.main.object(forInfoDictionaryKey: "FaqIndexUrl") as! String))!
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

    var bscscanKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "BscscanApiKey") as? String) ?? ""
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

    var defaultWords: String {
        Bundle.main.object(forInfoDictionaryKey: "DefaultWords") as? String ?? ""
    }

}





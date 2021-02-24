import Foundation
import CoinKit

class AppConfigProvider: IAppConfigProvider {
    let companyWebPageLink = "https://horizontalsystems.io"
    let appWebPageLink = "https://unstoppable.money"
    let appGitHubLink = "https://github.com/horizontalsystems/unstoppable-wallet-ios"
    let reportEmail = "support.unstoppable@protonmail.com"
    let telegramAccount = "unstoppable_announcements"
    let twitterAccount = "UnstoppableByHS"
    let redditAccount = "UNSTOPPABLEWallet"

    var guidesIndexUrl: URL {
        URL(string: (Bundle.main.object(forInfoDictionaryKey: "GuidesIndexUrl") as! String))!
    }

    var faqIndexUrl: URL {
        URL(string: (Bundle.main.object(forInfoDictionaryKey: "FaqIndexUrl") as! String))!
    }

    var uniswapSubgraphUrl: String {
        (Bundle.main.object(forInfoDictionaryKey: "UniswapGraphUrl") as? String) ?? ""
    }

    var testMode: Bool {
        Bundle.main.object(forInfoDictionaryKey: "TestMode") as? String == "true"
    }

    var officeMode: Bool {
        Bundle.main.object(forInfoDictionaryKey: "OfficeMode") as? String == "true"
    }

    var sandbox: Bool {
        Bundle.main.object(forInfoDictionaryKey: "Sandbox") as? String == "true"
    }

    func defaultWords(count: Int) -> String {
        Bundle.main.object(forInfoDictionaryKey: "DefaultWords\(count)") as? String ?? ""
    }

    var infuraCredentials: (id: String, secret: String?) {
        let id = (Bundle.main.object(forInfoDictionaryKey: "InfuraProjectId") as? String) ?? ""
        let secret = Bundle.main.object(forInfoDictionaryKey: "InfuraProjectSecret") as? String
        return (id: id, secret: secret)
    }

    var btcCoreRpcUrl: String {
        (Bundle.main.object(forInfoDictionaryKey: "BtcCoreRpcUrl") as? String) ?? ""
    }

    var etherscanKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "EtherscanApiKey") as? String) ?? ""
    }

    var bscscanKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "BscscanApiKey") as? String) ?? ""
    }

    var coinMarketCapApiKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "CoinMarketCapKey") as? String) ?? ""
    }

    var cryptoCompareApiKey: String? {
        (Bundle.main.object(forInfoDictionaryKey: "CryptoCompareApiKey") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    var pnsUrl: String {
        let development = "https://pns-dev.horizontalsystems.xyz/api/v1/"
        let production = "https://pns.horizontalsystems.xyz/api/v1/"

        return sandbox ? development : production
    }

    var pnsUsername: String {
        (Bundle.main.object(forInfoDictionaryKey: "PnsUsername") as? String) ?? ""
    }

    var pnsPassword: String {
        (Bundle.main.object(forInfoDictionaryKey: "PnsPassword") as? String) ?? ""
    }

    let currencyCodes: [String] = ["USD", "EUR", "GBP", "JPY"]
    let feeRateAdjustedForCurrencyCodes: [String] = ["USD", "EUR"]

    var featuredCoins: [Coin] {
        Array(CoinKit.Kit.defaultCoins(testNet: testMode).prefix(8))
    }

    let smartContractFees: [CoinType: Decimal] = [:]
    let minimumBalances: [CoinType: Decimal] = [.erc20(address: "0x039B5649A59967e3e936D7471f9c3700100Ee1ab"): 0.001]
    let minimumSpendableAmounts: [CoinType: Decimal] = [.erc20(address: "0x4f3AfEC4E5a3F2A6a1A411DEF7D7dFe50eE057bF"): 0.001]
}





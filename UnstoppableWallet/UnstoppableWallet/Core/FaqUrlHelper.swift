import Foundation

class FaqUrlHelper {

    static var privateKeysUrl: URL? {
        URL(string: "faq/en/management/what-are-private-keys-mnemonic-phrase-wallet-seed.md", relativeTo: AppConfig.faqIndexUrl)
    }

    static var walletConnectUrl: URL? {
        URL(string: "faq/en/defi/defi-risks.md", relativeTo: AppConfig.faqIndexUrl)
    }

}

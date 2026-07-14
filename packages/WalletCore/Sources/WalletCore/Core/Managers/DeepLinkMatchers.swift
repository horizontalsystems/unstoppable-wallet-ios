import Foundation

// A matcher either passes the url on (nil), consumes it silently (.handled — e.g. a malformed
// referral link), or resolves it into a DeepLink.
enum DeepLinkMatchResult {
    case handled
    case deepLink(DeepLinkManager.DeepLink)
}

protocol IDeepLinkMatcher {
    var route: DeepLinkRoute { get }
    func match(urlComponents: URLComponents, url: URL) -> DeepLinkMatchResult?
}

class WalletConnectDeepLinkMatcher: IDeepLinkMatcher {
    let route: DeepLinkRoute = .walletConnect

    func match(urlComponents: URLComponents, url _: URL) -> DeepLinkMatchResult? {
        let scheme = urlComponents.scheme
        let host = urlComponents.host
        let path = urlComponents.path

        guard (scheme == DeepLinkManager.deepLinkScheme && host == "wc") || (scheme == "https" && host == DeepLinkManager.deepLinkScheme && path == "/wc"),
              let uri = urlComponents.queryItems?.first(where: { $0.name == "uri" })?.value
        else {
            return nil
        }

        return .deepLink(.walletConnect(url: uri))
    }
}

class TonConnectDeepLinkMatcher: IDeepLinkMatcher {
    let route: DeepLinkRoute = .tonConnect

    func match(urlComponents: URLComponents, url _: URL) -> DeepLinkMatchResult? {
        let scheme = urlComponents.scheme
        let host = urlComponents.host
        let path = urlComponents.path

        guard (scheme == DeepLinkManager.deepLinkScheme && (host == DeepLinkManager.tonDeepLinkHost || host == DeepLinkManager.tonUniversalHost)) ||
            (scheme == "https" && host == DeepLinkManager.deepLinkScheme && path == "/\(DeepLinkManager.tonUniversalHost)"),
            let parameters = try? TonConnectManager.parseParameters(queryItems: urlComponents.queryItems)
        else {
            return nil
        }

        return .deepLink(.tonConnect(parameters: parameters))
    }
}

class TonTransferDeepLinkMatcher: IDeepLinkMatcher {
    let route: DeepLinkRoute = .tonTransfer

    func match(urlComponents: URLComponents, url: URL) -> DeepLinkMatchResult? {
        guard urlComponents.scheme == DeepLinkManager.tonDeepLinkScheme else {
            return nil
        }

        let parser = AddressParserFactory.parser(blockchainType: .ton, tokenType: nil)
        do {
            let address = try parser.parse(url: url.absoluteString)
            return .deepLink(.transfer(addressUri: address))
        } catch {
            // Parse error shows the banner but keeps the url falling through to the next matchers.
            HudHelper.instance.show(banner: .error(string: error.localizedDescription))
            return nil
        }
    }
}

class CoinDeepLinkMatcher: IDeepLinkMatcher {
    let route: DeepLinkRoute = .coin

    func match(urlComponents: URLComponents, url _: URL) -> DeepLinkMatchResult? {
        guard urlComponents.scheme == DeepLinkManager.deepLinkScheme, urlComponents.host == "coin" else {
            return nil
        }

        let uid = urlComponents.path.replacingOccurrences(of: "/", with: "")

        return .deepLink(.coin(uid: uid))
    }
}

class ReferralDeepLinkMatcher: IDeepLinkMatcher {
    let route: DeepLinkRoute = .referral

    func match(urlComponents: URLComponents, url _: URL) -> DeepLinkMatchResult? {
        let scheme = urlComponents.scheme
        let host = urlComponents.host
        let path = urlComponents.path

        guard (scheme == DeepLinkManager.deepLinkScheme && host == "referral") || (scheme == "https" && host == DeepLinkManager.deepLinkScheme && path == "/referral") else {
            return nil
        }

        guard let queryItems = urlComponents.queryItems, queryItems.count == 2,
              let userId = queryItems[0].value,
              let referralCode = queryItems[1].value
        else {
            // A referral-shaped url with malformed query is consumed silently, without the banner.
            return .handled
        }

        return .deepLink(.referral(telegramUserId: userId, referralCode: referralCode))
    }
}

class OpenCryptoPayDeepLinkMatcher: IDeepLinkMatcher {
    let route: DeepLinkRoute = .openCryptoPay

    func match(urlComponents _: URLComponents, url: URL) -> DeepLinkMatchResult? {
        guard let ocp = OpenCryptoPayUrl.detect(text: url.absoluteString) else {
            return nil
        }

        return .deepLink(.openCryptoPay(url: ocp))
    }
}

class TransferDeepLinkMatcher: IDeepLinkMatcher {
    let route: DeepLinkRoute = .transfer

    private let addressUriParser = AddressUriParser(blockchainType: nil, tokenType: nil)

    func match(urlComponents _: URLComponents, url: URL) -> DeepLinkMatchResult? {
        let encoded = url.absoluteString.removingPercentEncoding ?? url.absoluteString
        guard let uri = try? addressUriParser.parse(url: encoded) else {
            return nil
        }

        return .deepLink(.transfer(addressUri: uri))
    }
}

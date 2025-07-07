import BigInt
import Combine
import Foundation

class DeepLinkManager {
    static let deepLinkScheme = "unstoppable.money"
    static let tonDeepLinkScheme = "ton"
    static let tonUniversalHost = "ton-connect"
    static let tonDeepLinkHost = "tc"

    private let newSchemeSubject = CurrentValueSubject<DeepLink?, Never>(nil)
}

extension DeepLinkManager {
    var newSchemePublisher: AnyPublisher<DeepLink?, Never> {
        newSchemeSubject.eraseToAnyPublisher()
    }

    func handle(url: URL) {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return
        }

        let scheme = urlComponents.scheme
        let host = urlComponents.host
        let path = urlComponents.path
        let queryItems = urlComponents.queryItems

        if (scheme == DeepLinkManager.deepLinkScheme && host == "wc") || (scheme == "https" && host == DeepLinkManager.deepLinkScheme && path == "/wc"),
           let uri = queryItems?.first(where: { $0.name == "uri" })?.value
        {
            newSchemeSubject.send(.walletConnect(url: uri))
            return
        }

        if (scheme == DeepLinkManager.deepLinkScheme && (host == Self.tonDeepLinkHost || host == Self.tonUniversalHost)) ||
            (scheme == "https" && host == Self.deepLinkScheme && path == "/\(Self.tonUniversalHost)"),
            let parameters = try? TonConnectManager.parseParameters(queryItems: queryItems)
        {
            newSchemeSubject.send(.tonConnect(parameters: parameters))
            return
        }

        if scheme == Self.tonDeepLinkScheme {
            let parser = AddressParserFactory.parser(blockchainType: .ton, tokenType: nil)
            do {
                let address = try parser.parse(url: url.absoluteString)
                newSchemeSubject.send(.transfer(addressUri: address))
                return
            } catch {
                HudHelper.instance.show(banner: .error(string: error.localizedDescription))
            }
        }

        if scheme == DeepLinkManager.deepLinkScheme, host == "coin" {
            let uid = path.replacingOccurrences(of: "/", with: "")

            newSchemeSubject.send(.coin(uid: uid))
            return
        }

        if (scheme == DeepLinkManager.deepLinkScheme && host == "referral") || (scheme == "https" && host == DeepLinkManager.deepLinkScheme && path == "/referral") {
            guard let queryItems, queryItems.count == 2,
                  let userId = queryItems[0].value,
                  let referralCode = queryItems[1].value
            else {
                return
            }

            newSchemeSubject.send(.referral(telegramUserId: userId, referralCode: referralCode))
            return
        }
    }

    func setDeepLinkShown() {
        newSchemeSubject.send(nil)
    }
}

extension DeepLinkManager {
    enum DeepLink {
        case walletConnect(url: String)
        case tonConnect(parameters: TonConnectParameters)
        case coin(uid: String)
        case transfer(addressUri: AddressUri)
        case referral(telegramUserId: String, referralCode: String)
    }
}

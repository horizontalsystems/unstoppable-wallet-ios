import BigInt
import ComponentKit
import Foundation
import RxRelay
import RxSwift

class DeepLinkManager {
    static let deepLinkScheme = "unstoppable.money"
    static let tonDeepLinkScheme = "ton"

    private let newSchemeRelay = BehaviorRelay<DeepLink?>(value: nil)
}

extension DeepLinkManager {
    var newSchemeObservable: Observable<DeepLink?> {
        newSchemeRelay.asObservable()
    }

    func handle(url: URL) -> Bool {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return false
        }

        let scheme = urlComponents.scheme
        let host = urlComponents.host
        let path = urlComponents.path
        let queryItems = urlComponents.queryItems

        if (scheme == DeepLinkManager.deepLinkScheme && host == "wc") || (scheme == "https" && host == DeepLinkManager.deepLinkScheme && path == "/wc"),
           let uri = queryItems?.first(where: { $0.name == "uri" })?.value
        {
            newSchemeRelay.accept(.walletConnect(url: uri))
            return true
        }

        if scheme == Self.tonDeepLinkScheme {
            let parser = AddressParserFactory.parser(blockchainType: .ton, tokenType: nil)
            do {
                let address = try parser.parse(url: url.absoluteString)
                newSchemeRelay.accept(.transfer(addressUri: address))
                return true
            } catch {
                HudHelper.instance.show(banner: .error(string: error.localizedDescription))
            }
        }

        if scheme == DeepLinkManager.deepLinkScheme, host == "coin" {
            let uid = path.replacingOccurrences(of: "/", with: "")

            newSchemeRelay.accept(.coin(uid: uid))
            return true
        }

        if (scheme == DeepLinkManager.deepLinkScheme && host == "referral") || (scheme == "https" && host == DeepLinkManager.deepLinkScheme && path == "/referral") {
            guard let queryItems, queryItems.count == 2,
                  let userId = queryItems[0].value,
                  let referralCode = queryItems[1].value
            else {
                return false
            }

            newSchemeRelay.accept(.referral(telegramUserId: userId, referralCode: referralCode))
            return true
        }

        return false
    }

    func setDeepLinkShown() {
        newSchemeRelay.accept(nil)
    }
}

extension DeepLinkManager {
    enum DeepLink {
        case walletConnect(url: String)
        case coin(uid: String)
        case transfer(addressUri: AddressUri)
        case referral(telegramUserId: String, referralCode: String)
    }
}

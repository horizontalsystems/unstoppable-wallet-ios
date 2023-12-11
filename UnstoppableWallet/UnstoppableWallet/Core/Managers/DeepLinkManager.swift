import ComponentKit
import Foundation
import RxRelay
import RxSwift

class DeepLinkManager {
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

        if (scheme == "unstoppable.money" && host == "wc") || (scheme == "https" && host == "unstoppable.money" && path == "/wc"),
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
            } catch {
                HudHelper.instance.show(banner: .error(string: error.localizedDescription))
            }
        }

        if scheme == "unstoppable.money", host == "coin" {
            let uid = path.replacingOccurrences(of: "/", with: "")

            newSchemeRelay.accept(.coin(uid: uid))
            return true
        }

        return false
    }
}

extension DeepLinkManager {
    enum DeepLink {
        case walletConnect(url: String)
        case coin(uid: String)
        case transfer(addressUri: AddressUri)
    }
}

import Combine
import Foundation

class DeepLinkManager {
    static let deepLinkScheme = "unstoppable.money"
    static let tonDeepLinkScheme = "ton"
    static let tonUniversalHost = "ton-connect"
    static let tonDeepLinkHost = "tc"

    private let newSchemeSubject = CurrentValueSubject<DeepLink?, Never>(nil)
    private let matchers: [IDeepLinkMatcher]

    init(matchers: [IDeepLinkMatcher]) {
        self.matchers = matchers
    }
}

extension DeepLinkManager {
    var newSchemePublisher: AnyPublisher<DeepLink?, Never> {
        newSchemeSubject.eraseToAnyPublisher()
    }

    func handle(url: URL) {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return
        }

        for matcher in matchers {
            guard let result = matcher.match(urlComponents: urlComponents, url: url) else {
                continue
            }

            switch result {
            case .handled:
                return
            case let .deepLink(deepLink):
                newSchemeSubject.send(deepLink)
                return
            }
        }

        HudHelper.instance.show(banner: .error(string: "alert.cant_recognize".localized))
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
        case openCryptoPay(url: URL)
    }
}

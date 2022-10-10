import Foundation
import RxSwift
import RxRelay

class DeepLinkManager {
    private let newSchemeRelay = BehaviorRelay<DeepLink?>(value: nil)
}

extension DeepLinkManager {

    func handle(url: URL) -> Bool {
        guard url.path.contains("wc"), let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems, let uri = queryItems.first(where: { $0.name == "uri" })?.value else {
            return false
        }

        if url.scheme == "moneyunstoppable" || url.scheme == "https" {
            newSchemeRelay.accept(.walletConnect(url: uri))

            return true
        }

        return false
    }

    var newSchemeObservable: Observable<DeepLink?> {
        newSchemeRelay.asObservable()
    }

}

extension DeepLinkManager {

    enum DeepLink {
        case walletConnect(url: String)
    }

}

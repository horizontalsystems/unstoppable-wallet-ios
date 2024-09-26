import Foundation

struct TonConnectManifest: Codable, Equatable {
    let url: URL
    let name: String
    let iconUrl: URL?
    let termsOfUseUrl: URL?
    let privacyPolicyUrl: URL?

    var host: String {
        url.host ?? ""
    }
}

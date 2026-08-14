import Foundation
import MarketKit
import RxRelay
import RxSwift

class AddMoneroNodeService {
    let blockchainType: BlockchainType
    private let moneroNodeManager: MoneroNodeManager
    private var disposeBag = DisposeBag()

    private var urlString: String = ""
    private var login: String = ""
    private var password: String = ""

    init(blockchainType: BlockchainType, moneroNodeManager: MoneroNodeManager) {
        self.blockchainType = blockchainType
        self.moneroNodeManager = moneroNodeManager
    }
}

extension AddMoneroNodeService {
    func set(urlString: String) {
        self.urlString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func set(login: String) {
        self.login = login.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func set(password: String) {
        self.password = password.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Existing entries may be bare "host:port" strings, so duplicates are matched on the
    // canonical host:port rather than the raw URL string.
    private static func canonical(url: URL) -> String? {
        let raw = url.absoluteString
        let normalized = raw.hasPrefix("http://") || raw.hasPrefix("https://") ? raw : "https://\(raw)"

        guard let components = URLComponents(string: normalized), let host = components.host else {
            return nil
        }

        let port = components.port ?? (components.scheme == "http" ? 80 : 443)
        return "\(host):\(port)"
    }

    func save() throws {
        guard let url = URL(string: urlString), let scheme = url.scheme else {
            throw UrlError.invalid
        }

        guard scheme == "https" else {
            throw UrlError.invalid
        }

        guard url.port != nil else {
            throw UrlError.portRequired
        }

        let existingNodes = moneroNodeManager.allNodes(blockchainType: blockchainType)
        let newCanonical = Self.canonical(url: url)

        guard !existingNodes.contains(where: { Self.canonical(url: $0.node.url) == newCanonical }) else {
            throw UrlError.alreadyExists
        }

        let login = login.isEmpty ? nil : login
        let password = password.isEmpty ? nil : password

        stat(page: .blockchainSettingsMoneroAdd, event: .addMoneroNode(chainUid: blockchainType.uid))
        moneroNodeManager.addNew(blockchainType: blockchainType, url: url, isTrusted: true, login: login, password: password)
    }
}

extension AddMoneroNodeService {
    enum UrlError: Error {
        case invalid
        case portRequired
        case alreadyExists
    }
}

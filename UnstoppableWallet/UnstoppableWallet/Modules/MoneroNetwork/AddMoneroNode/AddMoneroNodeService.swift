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

    func save() throws {
        guard let url = URL(string: urlString), let scheme = url.scheme else {
            throw UrlError.invalid
        }

        guard scheme == "https" else {
            throw UrlError.invalid
        }

        let existingNodes = moneroNodeManager.allNodes(blockchainType: blockchainType)

        guard !existingNodes.contains(where: { $0.node.url == url }) else {
            throw UrlError.alreadyExists
        }

        let login = login.isEmpty ? nil : login
        let password = password.isEmpty ? nil : password

        stat(page: .blockchainSettingsMoneroAdd, event: .addMoneroNode(chainUid: blockchainType.uid))
        moneroNodeManager.saveNode(blockchainType: blockchainType, url: url, isTrusted: false, login: login, password: password)
    }
}

extension AddMoneroNodeService {
    enum UrlError: Error {
        case invalid
        case alreadyExists
    }
}

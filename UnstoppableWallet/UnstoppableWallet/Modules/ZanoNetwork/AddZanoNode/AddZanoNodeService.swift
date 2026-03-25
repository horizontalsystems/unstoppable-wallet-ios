import Foundation
import MarketKit
import RxRelay
import RxSwift

class AddZanoNodeService {
    let blockchainType: BlockchainType
    private let zanoNodeManager: ZanoNodeManager

    private var urlString: String = ""

    init(blockchainType: BlockchainType, zanoNodeManager: ZanoNodeManager) {
        self.blockchainType = blockchainType
        self.zanoNodeManager = zanoNodeManager
    }
}

extension AddZanoNodeService {
    func set(urlString: String) {
        self.urlString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func save() throws {
        guard let url = URL(string: urlString), url.scheme != nil, url.host != nil else {
            throw UrlError.invalid
        }

        let existingNodes = zanoNodeManager.allNodes(blockchainType: blockchainType)

        guard !existingNodes.contains(where: { $0.url == url }) else {
            throw UrlError.alreadyExists
        }

        stat(page: .blockchainSettingsZanoAdd, event: .addZanoNode(chainUid: blockchainType.uid))
        zanoNodeManager.addNew(blockchainType: blockchainType, url: url)
    }
}

extension AddZanoNodeService {
    enum UrlError: Error {
        case invalid
        case alreadyExists
    }
}

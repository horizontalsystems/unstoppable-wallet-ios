import Foundation
import RxSwift
import RxRelay
import EvmKit
import MarketKit

class AddEvmSyncSourceService {
    private let blockchainType: BlockchainType
    private let evmSyncSourceManager: EvmSyncSourceManager
    private var disposeBag = DisposeBag()

    private var urlString: String = ""
    private var basicAuth: String = ""

    init(blockchainType: BlockchainType, evmSyncSourceManager: EvmSyncSourceManager) {
        self.blockchainType = blockchainType
        self.evmSyncSourceManager = evmSyncSourceManager
    }

}

extension AddEvmSyncSourceService {

    func set(urlString: String) {
        self.urlString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func set(basicAuth: String) {
        self.basicAuth = basicAuth.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func save() throws {
        guard let url = URL(string: urlString), let scheme = url.scheme else {
            throw UrlError.invalid
        }

        guard ["https", "wss"].contains(scheme) else {
            throw UrlError.invalid
        }

        let existingSources = evmSyncSourceManager.allSyncSources(blockchainType: blockchainType)

        guard !existingSources.contains(where: { $0.rpcSource.url == url }) else {
            throw UrlError.alreadyExists
        }

        let auth = basicAuth.isEmpty ? nil : basicAuth

        evmSyncSourceManager.saveSyncSource(blockchainType: blockchainType, url: url, auth: auth)
    }

}

extension AddEvmSyncSourceService {

    enum UrlError: Error {
        case invalid
        case alreadyExists
    }

}

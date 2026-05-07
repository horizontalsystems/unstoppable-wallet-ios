import GRDB
import TonSwift

struct TonConnectApp: Codable, Identifiable {
    let accountId: String
    let clientId: String
    let manifest: TonConnectManifest
    let keyPair: TonSwift.KeyPair

    var id: String {
        clientId
    }
}

extension TonConnectApp: FetchableRecord, PersistableRecord {
    enum Columns {
        static let accountId = Column(CodingKeys.accountId)
        static let clientId = Column(CodingKeys.clientId)
        static let manifest = Column(CodingKeys.manifest)
        static let keyPair = Column(CodingKeys.keyPair)
    }
}

struct TonConnectLastEvent: Codable {
    let uniqueField: String
    let id: String

    init(id: String) {
        uniqueField = "unique"
        self.id = id
    }
}

extension TonConnectLastEvent: FetchableRecord, PersistableRecord {
    enum Columns {
        static let uniqueField = Column(CodingKeys.uniqueField)
        static let id = Column(CodingKeys.id)
    }
}

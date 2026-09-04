import Foundation
import GRDB

struct WCNSessionRecord: Codable {
    let topic: String
    let accountId: String
    let dAppName: String
    let namespaces: Data

    init(topic: String, accountId: String, dAppName: String, namespaces: WCNSessionNamespaces) throws {
        self.topic = topic
        self.accountId = accountId
        self.dAppName = dAppName
        self.namespaces = try JSONEncoder().encode(namespaces)
    }

    func sessionNamespaces() throws -> WCNSessionNamespaces {
        try JSONDecoder().decode(WCNSessionNamespaces.self, from: namespaces)
    }
}

extension WCNSessionRecord: FetchableRecord, PersistableRecord {
    static let databaseTableName = "wcnSession"

    enum Columns {
        static let topic = Column(CodingKeys.topic)
        static let accountId = Column(CodingKeys.accountId)
        static let dAppName = Column(CodingKeys.dAppName)
        static let namespaces = Column(CodingKeys.namespaces)
    }
}

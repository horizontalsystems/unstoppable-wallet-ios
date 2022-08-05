import GRDB

class WalletConnectV2Session: Codable, FetchableRecord, PersistableRecord, TableRecord {
    let accountId: String
    let topic: String

    init(accountId: String, topic: String) {
        self.accountId = accountId
        self.topic = topic
    }

    class var databaseTableName: String {
        "wallet_connect_sessions_v2"
    }

    enum Columns {
        static let accountId = Column(CodingKeys.accountId)
        static let topic = Column(CodingKeys.topic)
    }

}

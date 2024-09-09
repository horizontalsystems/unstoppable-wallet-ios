import GRDB

struct RestoreState: Codable {
    let accountId: String
    let blockchainUid: String
    var shouldRestore: Bool
    var initialRestored: Bool

    init(accountId: String, blockchainUid: String, shouldRestore: Bool = false, initialRestored: Bool = false) {
        self.accountId = accountId
        self.blockchainUid = blockchainUid
        self.shouldRestore = shouldRestore
        self.initialRestored = initialRestored
    }
}

extension RestoreState: FetchableRecord, PersistableRecord {
    enum Columns {
        static let accountId = Column(CodingKeys.accountId)
        static let blockchainUid = Column(CodingKeys.blockchainUid)
        static let shouldRestore = Column(CodingKeys.shouldRestore)
        static let initialRestored = Column(CodingKeys.initialRestored)
    }
}

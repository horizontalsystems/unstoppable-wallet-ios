import GRDB
import WalletConnectV1

class WalletConnectSession: Codable, FetchableRecord, PersistableRecord, TableRecord {
    let chainId: Int
    let accountId: String
    let session: WCSession
    let peerId: String
    let peerMeta: WCPeerMeta

    init(chainId: Int, accountId: String, session: WCSession, peerId: String, peerMeta: WCPeerMeta) {
        self.chainId = chainId
        self.accountId = accountId
        self.session = session
        self.peerId = peerId
        self.peerMeta = peerMeta
    }

    class var databaseTableName: String {
        "wallet_connect_sessions"
    }

    enum Columns {
        static let chainId = Column(CodingKeys.chainId)
        static let accountId = Column(CodingKeys.accountId)
        static let session = Column(CodingKeys.session)
        static let peerId = Column(CodingKeys.peerId)
        static let peerMeta = Column(CodingKeys.peerMeta)
    }

}

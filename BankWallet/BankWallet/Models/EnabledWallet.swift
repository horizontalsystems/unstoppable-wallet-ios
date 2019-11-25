import GRDB

class EnabledWallet: Record {
    let coinId: String
    let accountId: String

    var derivation: MnemonicDerivation?
    var syncMode: SyncMode?

    init(coinId: String, accountId: String, derivation: MnemonicDerivation?, syncMode: SyncMode?) {
        self.coinId = coinId
        self.accountId = accountId

        self.derivation = derivation
        self.syncMode = syncMode

        super.init()
    }

    override class var databaseTableName: String {
        "enabled_wallets"
    }

    enum Columns: String, ColumnExpression {
        case coinId, accountId, derivation, syncMode
    }

    required init(row: Row) {
        coinId = row[Columns.coinId]
        accountId = row[Columns.accountId]

        if let rawSyncMode: String = row[Columns.syncMode] {
            syncMode = SyncMode(rawValue: rawSyncMode)
        }

        if let rawDerivation: String = row[Columns.derivation] {
            derivation = MnemonicDerivation(rawValue: rawDerivation)
        }

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.coinId] = coinId
        container[Columns.accountId] = accountId

        container[Columns.syncMode] = syncMode?.rawValue
        container[Columns.derivation] = derivation?.rawValue
    }

}

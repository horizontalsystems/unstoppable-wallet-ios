class Account {
    let id: String
    let name: String
    let type: AccountType
    var backedUp: Bool
    var defaultSyncMode: SyncMode?

    init(id: String, name: String, type: AccountType, backedUp: Bool, defaultSyncMode: SyncMode?) {
        self.id = id
        self.name = name
        self.type = type
        self.backedUp = backedUp
        self.defaultSyncMode = defaultSyncMode
    }

}

extension Account: Equatable {

    public static func ==(lhs: Account, rhs: Account) -> Bool {
        return lhs.id == rhs.id
    }

}

class Account {
    let id: String
    var name: String
    let type: AccountType
    let origin: AccountOrigin
    var backedUp: Bool

    init(id: String, name: String, type: AccountType, origin: AccountOrigin, backedUp: Bool) {
        self.id = id
        self.name = name
        self.type = type
        self.origin = origin
        self.backedUp = backedUp
    }

    var watchAccount: Bool {
        switch type {
        case .evmAddress:
            return true
        case .hdExtendedKey(let key):
            switch key {
            case .public: return true
            default: return false
            }
        default:
            return false
        }
    }

}

extension Account: Hashable {

    public static func ==(lhs: Account, rhs: Account) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

}

enum AccountOrigin: String {
    case created
    case restored
}

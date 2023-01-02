enum ZcashRestoreType: String, CaseIterable {
    case new
    case old

    var title: String {
        switch self {
        case .new: return "birthday_input.new_wallet".localized
        case .old: return "birthday_input.old_wallet".localized
        }
    }

    var description: String {
        switch self {
        case .new: return "birthday_input.new_wallet.description".localized
        case .old: return "birthday_input.old_wallet.description".localized
        }
    }
}

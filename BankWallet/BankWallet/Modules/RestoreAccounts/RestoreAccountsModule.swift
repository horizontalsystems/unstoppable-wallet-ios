protocol IRestoreAccountsViewDelegate {
    var itemsCount: Int { get }
    func item(index: Int) -> RestoreAccountViewItem

    func didTapRestore(index: Int)
}

protocol IRestoreAccountsRouter {
    func showRestore(type: RestoreType)
}

struct RestoreAccountViewItem {
    let title: String
    let coinCodes: String
}

enum RestoreType: Int, CaseIterable {
    case words12
    case account
    case words24

    var title: String {
        switch self {
        case .words12: return "key_type.12_words"
        case .account: return "key_type.eos"
        case .words24: return "key_type.24_words"
        }
    }

    var coinCodes: String {
        switch self {
        case .words12: return "BTC, BCH, DASH, ETH, ERC-20"
        case .account: return "EOS"
        case .words24: return "BNB"
        }
    }

}
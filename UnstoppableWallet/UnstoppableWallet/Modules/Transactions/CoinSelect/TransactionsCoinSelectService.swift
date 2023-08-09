import RxSwift
import RxRelay
import MarketKit

class TransactionsCoinSelectService {
    private let token: Token?
    private let walletManager: WalletManager
    private weak var delegate: ITransactionsCoinSelectDelegate?
    private let disposeBag = DisposeBag()

    private let itemsRelay = PublishRelay<[Item]>()
    private(set) var items: [Item] = [] {
        didSet {
            itemsRelay.accept(items)
        }
    }

    private var filter: String = ""

    init(token: Token?, walletManager: WalletManager, delegate: ITransactionsCoinSelectDelegate?) {
        self.token = token
        self.walletManager = walletManager
        self.delegate = delegate

        syncItems()
    }

    private func syncItems() {
        var items = walletManager.activeWallets
                .filter { wallet in
                    guard !filter.isEmpty else {
                        return true
                    }

                    return wallet.coin.name.localizedCaseInsensitiveContains(filter) || wallet.coin.code.localizedCaseInsensitiveContains(filter)
                }
                .sorted { lhsWallet, rhsWallet in
                    let lhsName = lhsWallet.coin.name.lowercased()
                    let rhsName = rhsWallet.coin.name.lowercased()

                    if lhsName != rhsName {
                        return lhsName < rhsName
                    }

                    return lhsWallet.token.badge ?? "" < rhsWallet.token.badge ?? ""
                }
                .map { wallet in
                    Item(
                            type: .token(token: wallet.token),
                            selected: wallet.token == token
                    )
                }

        if filter.isEmpty {
            items.insert(Item(type: .all, selected: token == nil), at: 0)
        }

        self.items = items
    }

}

extension TransactionsCoinSelectService {

    var itemsObservable: Observable<[Item]> {
        itemsRelay.asObservable()
    }

    func set(filter: String) {
        self.filter = filter

        syncItems()
    }

    func handleSelected(index: Int) {
        guard index < items.count else {
            return
        }

        switch items[index].type {
        case .all:
            delegate?.didSelect(token: nil)
        case .token(let configuredToken):
            delegate?.didSelect(token: configuredToken)
        }
    }

}

extension TransactionsCoinSelectService {

    struct Item {
        let type: ItemType
        let selected: Bool
    }

    enum ItemType {
        case all
        case token(token: Token)
    }

}

import RxSwift
import RxRelay
import MarketKit

class TransactionsCoinSelectService {
    private let configuredToken: ConfiguredToken?
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

    init(configuredToken: ConfiguredToken?, walletManager: WalletManager, delegate: ITransactionsCoinSelectDelegate?) {
        self.configuredToken = configuredToken
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

                    return lhsWallet.configuredToken.badge ?? "" < rhsWallet.configuredToken.badge ?? ""
                }
                .map { wallet in
                    Item(
                            type: .token(configuredToken: wallet.configuredToken),
                            selected: wallet.configuredToken == configuredToken
                    )
                }

        if filter.isEmpty {
            items.insert(Item(type: .all, selected: configuredToken == nil), at: 0)
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
            delegate?.didSelect(configuredToken: nil)
        case .token(let configuredToken):
            delegate?.didSelect(configuredToken: configuredToken)
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
        case token(configuredToken: ConfiguredToken)
    }

}

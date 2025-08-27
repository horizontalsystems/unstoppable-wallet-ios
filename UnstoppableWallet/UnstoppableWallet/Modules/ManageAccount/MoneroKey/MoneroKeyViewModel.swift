import RxCocoa
import RxRelay
import RxSwift

class MoneroKeyViewModel {
    private let spendKey: String
    private let viewKey: String
    private let mode: Mode

    private let keyTypeChangedRelay = BehaviorRelay<Void>(value: ())

    var keyType: KeyType

    var key: String {
        switch keyType {
        case .spend: return spendKey
        case .view: return viewKey
        }
    }

    var showingPrivateKeys: Bool {
        mode == .privateKeys
    }

    var keyTypeViewItems: [AlertViewItem] {
        KeyType.allCases.map { _keyType in
            AlertViewItem(
                text: "monero.key_types.\(_keyType.rawValue)".localized,
                selected: keyType == _keyType
            )
        }
    }

    var keyTypeChangedDriver: Driver<Void> {
        keyTypeChangedRelay.asDriver()
    }

    init?(accountType: AccountType, mode: Mode) {
        self.mode = mode
        keyType = .spend

        switch mode {
        case .privateKeys:
            spendKey = MoneroAdapter.key(accountType: accountType, privateKey: true, spendKey: true)
            viewKey = MoneroAdapter.key(accountType: accountType, privateKey: true, spendKey: false)

        case .publicKeys:
            spendKey = MoneroAdapter.key(accountType: accountType, privateKey: false, spendKey: true)
            viewKey = MoneroAdapter.key(accountType: accountType, privateKey: false, spendKey: false)
        }
    }

    func onSelectKeyType(index: Int) {
        keyType = KeyType.allCases[index]
        keyTypeChangedRelay.accept(())
        stat(page: showingPrivateKeys ? .moneroPrivateKeys : .moneroPublicKeys, event: .select(entity: .moneroKeyType))
    }
}

extension MoneroKeyViewModel {
    enum Mode {
        case privateKeys, publicKeys
    }

    enum KeyType: String, CaseIterable {
        case spend, view
    }
}

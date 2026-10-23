import Combine

class MoneroKeyViewModel: ObservableObject {
    let mode: Mode
    private let spendKey: String
    private let viewKey: String

    @Published private(set) var keyType: KeyType = .spend
    @Published private(set) var hidden = true

    init(accountType: AccountType, mode: Mode) {
        self.mode = mode

        switch mode {
        case .privateKeys:
            spendKey = MoneroAdapter.key(accountType: accountType, privateKey: true, spendKey: true)
            viewKey = MoneroAdapter.key(accountType: accountType, privateKey: true, spendKey: false)
        case .publicKeys:
            spendKey = MoneroAdapter.key(accountType: accountType, privateKey: false, spendKey: true)
            viewKey = MoneroAdapter.key(accountType: accountType, privateKey: false, spendKey: false)
        }
    }

    var key: String {
        switch keyType {
        case .spend: return spendKey
        case .view: return viewKey
        }
    }

    var showingPrivateKeys: Bool {
        mode == .privateKeys
    }

    var title: String {
        showingPrivateKeys ? "monero_private_key.title".localized : "monero_public_key.title".localized
    }

    var statPage: StatPage {
        showingPrivateKeys ? .moneroPrivateKeys : .moneroPublicKeys
    }

    var keyTypeViewItems: [AlertViewItem] {
        KeyType.allCases.map { _keyType in
            AlertViewItem(
                text: _keyType.title,
                selected: keyType == _keyType
            )
        }
    }

    func onSelectKeyType(index: Int) {
        keyType = KeyType.allCases[index]
        hidden = true
        stat(page: statPage, event: .select(entity: .moneroKeyType))
    }

    func toggleHidden() {
        hidden.toggle()
        stat(page: statPage, event: .toggleHidden)
    }

    func copy() {
        let statPage = statPage

        if showingPrivateKeys {
            Coordinator.shared.presentCopyConfirmation(value: key) {
                stat(page: statPage, event: .copy(entity: .moneroKey))
            }
        } else {
            CopyHelper.copyAndNotify(value: key)
            stat(page: statPage, event: .copy(entity: .moneroKey))
        }
    }
}

extension MoneroKeyViewModel {
    enum Mode {
        case privateKeys, publicKeys
    }

    enum KeyType: String, CaseIterable {
        case spend, view

        var title: String {
            switch self {
            case .spend: return "Spend"
            case .view: return "View"
            }
        }
    }
}

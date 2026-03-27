import Combine
import MarketKit

class AccountTypeSelectViewModel {
    private let marketKit = Core.shared.marketKit
    private let accountFactory = Core.shared.accountFactory
    private let accountManager = Core.shared.accountManager
    private let accountName: String
    let items: [ViewItem]

    private let openSelectCoinsSubject = PassthroughSubject<AccountType, Never>()
    private let onSuccessSubject = PassthroughSubject<AccountType, Never>()

    init(accountName: String, accountTypes: [AccountType]) {
        items = accountTypes.compactMap { type in
            Self.viewItem(accountType: type)
        }
        self.accountName = accountName
    }

    private static func viewItem(accountType: AccountType) -> ViewItem? {
        switch accountType {
        case .evmPrivateKey:
            return .init(title: "restore.select_key_type.evm".localized, description: "restore.select_key_type.evm.description".localized, accountType: accountType)
        case .trcPrivateKey:
            return .init(title: "restore.select_key_type.trc".localized, description: "restore.select_key_type.trc.description".localized, accountType: accountType)
        default: return nil
        }
    }

    func onTap(index: Int) {
        guard let item = items.at(index: index) else { return }

        switch item.accountType {
        case .evmPrivateKey: openSelectCoinsSubject.send(item.accountType)
        case .trcPrivateKey: restore(item.accountType)
        default: ()
        }
    }

    private func restore(_ accountType: AccountType) {
        let account = accountFactory.account(
            type: accountType,
            origin: .restored,
            backedUp: true,
            fileBackedUp: false,
            name: accountName
        )
        accountManager.save(account: account)

        let tokenQuery = TokenQuery(blockchainType: .tron, tokenType: .native)
        if let token = try? Core.shared.marketKit.token(query: tokenQuery) {
            Core.shared.restoreStateManager.setShouldRestore(account: account, blockchainType: .tron)
            let wallet = Wallet(token: token, account: account)
            Core.shared.walletManager.save(wallets: [wallet])
        }

        onSuccessSubject.send(accountType)
    }
}

extension AccountTypeSelectViewModel {
    var openSelectCoinsPublisher: AnyPublisher<AccountType, Never> {
        openSelectCoinsSubject.eraseToAnyPublisher()
    }

    var onSuccessPublisher: AnyPublisher<AccountType, Never> {
        onSuccessSubject.eraseToAnyPublisher()
    }
}

extension AccountTypeSelectViewModel {
    struct ViewItem {
        let title: String
        let description: String
        let accountType: AccountType
    }
}

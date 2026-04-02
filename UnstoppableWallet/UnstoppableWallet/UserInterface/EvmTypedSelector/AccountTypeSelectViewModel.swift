import Combine
import MarketKit

class AccountTypeSelectViewModel {
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
        let supportedTokens = RestoreSelectModule.supportedTokens(accountType: accountType)

        if let token = supportedTokens.first {
            RestoreSelectModule.restoreSingleBlockchain(accountName: accountName, accountType: accountType, token: token)
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

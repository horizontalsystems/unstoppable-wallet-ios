import RxSwift
import EthereumKit

class WalletConnectListService {
    private let predefinedAccountTypeManager: IPredefinedAccountTypeManager
    private let sessionManager: WalletConnectSessionManager

    init(predefinedAccountTypeManager: IPredefinedAccountTypeManager, sessionManager: WalletConnectSessionManager) {
        self.predefinedAccountTypeManager = predefinedAccountTypeManager
        self.sessionManager = sessionManager
    }

    private func evmAddress(chainId: Int, accountType: AccountType) -> EthereumKit.Address? {
        guard case let .mnemonic(words, _) = accountType else {
            return nil
        }

        if chainId == 1 {
            return try? EthereumKit.Kit.address(words: words, networkType: .ethMainNet)
        }

        if chainId == 56 {
            return try? EthereumKit.Kit.address(words: words, networkType: .bscMainNet)
        }

        return nil
    }

    private func items(sessions: [WalletConnectSession]) -> [Item] {
        predefinedAccountTypeManager.allTypes.compactMap { type in
            guard let account = predefinedAccountTypeManager.account(predefinedAccountType: type) else {
                return nil
            }

            let accountSessions = sessions.filter { $0.accountId == account.id }

            guard !accountSessions.isEmpty else {
                return nil
            }

            guard let address = evmAddress(chainId: accountSessions[0].chainId, accountType: account.type) else {
                return nil
            }

            return Item(predefinedAccountType: type, address: address, sessions: accountSessions)
        }
    }

}

extension WalletConnectListService {

    var items: [Item] {
        items(sessions: sessionManager.sessions)
    }

    var itemsObservable: Observable<[Item]> {
        sessionManager.sessionsObservable.map { [weak self] in
            self?.items(sessions: $0) ?? []
        }
    }

}

extension WalletConnectListService {

    struct Item {
        let predefinedAccountType: PredefinedAccountType
        let address: EthereumKit.Address
        let sessions: [WalletConnectSession]
    }

}

import RxSwift
import EthereumKit

class WalletConnectListService {
    private let sessionManager: WalletConnectSessionManager

    init(sessionManager: WalletConnectSessionManager) {
        self.sessionManager = sessionManager
    }

    private func items(sessions: [WalletConnectSession]) -> [Item] {
        Chain.allCases.compactMap { chain in
            let sessions = sessions.filter { $0.chainId == chain.rawValue }

            guard !sessions.isEmpty else {
                return nil
            }

            return Item(chain: chain, sessions: sessions)
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

    enum Chain: Int, CaseIterable {
        case ethereum = 1
        case binanceSmartChain = 56
    }

    struct Item {
        let chain: Chain
        let sessions: [WalletConnectSession]
    }

}

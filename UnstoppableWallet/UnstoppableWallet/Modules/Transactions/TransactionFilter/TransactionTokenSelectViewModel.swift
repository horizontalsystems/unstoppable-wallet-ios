import Combine
import MarketKit

class TransactionTokenSelectViewModel: ObservableObject {
    private let transactionFilterViewModel: TransactionFilterViewModel
    private let walletManager = App.shared.walletManager
    private let transactionAdapterManager = App.shared.transactionAdapterManager
    private let marketKit = App.shared.marketKit

    let tokens: [Token]

    init(transactionFilterViewModel: TransactionFilterViewModel) {
        self.transactionFilterViewModel = transactionFilterViewModel

        var tokens = walletManager.activeWallets.map(\.token)

        var tokenQueries = [TokenQuery]()

        for adapter in transactionAdapterManager.adapterMap.values {
            tokenQueries.append(contentsOf: adapter.additionalTokenQueries)
        }

        try? tokens.append(contentsOf: marketKit.tokens(queries: tokenQueries))

        self.tokens = tokens.removeDuplicates().sorted { lhsToken, rhsToken in
            let lhsName = lhsToken.coin.name.lowercased()
            let rhsName = rhsToken.coin.name.lowercased()

            if lhsName != rhsName {
                return lhsName < rhsName
            }

            return lhsToken.badge ?? "" < rhsToken.badge ?? ""
        }
    }

    var currentToken: Token? {
        transactionFilterViewModel.token
    }

    func set(currentToken: Token?) {
        transactionFilterViewModel.set(token: currentToken)
    }
}

import Combine
import MarketKit

class MarketVaultViewModel: ObservableObject {
    private let currencyManager = Core.shared.currencyManager

    let vault: Vault
    let blockchain: Blockchain?

    init(vault: Vault, blockchain: Blockchain?) {
        self.vault = vault
        self.blockchain = blockchain
    }
}

extension MarketVaultViewModel {
    var currency: Currency {
        currencyManager.baseCurrency
    }
}

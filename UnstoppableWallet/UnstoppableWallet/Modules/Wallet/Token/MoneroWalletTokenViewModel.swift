import Combine
import Foundation

class MoneroWalletTokenViewModel: ObservableObject {
    private let adapterManager = Core.shared.adapterManager
    private let restoreSettingsService = RestoreSettingsService(manager: Core.shared.restoreSettingsManager)
    private let adapter: MoneroAdapter

    let wallet: Wallet

    @Published var birthdayHeight: Int?

    init(adapter: MoneroAdapter, wallet: Wallet) {
        self.adapter = adapter
        self.wallet = wallet

        birthdayHeight = restoreSettingsService.settings(accountId: wallet.account.id, blockchainType: wallet.token.blockchainType).birthdayHeight
    }
}

extension MoneroWalletTokenViewModel {
    func onChange(birthdayHeight: Int) {
        let blockchainType = wallet.token.blockchainType
        restoreSettingsService.set(birthdayHeight: birthdayHeight, account: wallet.account, blokcchainType: blockchainType)
        self.birthdayHeight = birthdayHeight

        adapterManager.recreateAdapter(blockchainType: blockchainType)
    }
}
